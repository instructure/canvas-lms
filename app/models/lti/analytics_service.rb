#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require 'duration'
require 'net/http'
require 'securerandom'

module Lti
  class AnalyticsService
    class Token < Struct.new(:tool, :user, :course, :timestamp, :nonce)
      def self.create(tool, user, course)
        Token.new(tool, user, course, Time.now, SecureRandom.hex(8))
      end

      def serialize
        key = tool.shard.settings[:encryption_key]
        payload = [tool.id, user.id, course.id, timestamp.to_i, nonce].join('-')
        "#{payload}-#{Canvas::Security.hmac_sha1(payload, key)}"
      end

      def self.parse_and_validate(serialized_token)
        parts = serialized_token.split('-')
        tool = ContextExternalTool.find(parts[0].to_i)
        key = tool.shard.settings[:encryption_key]
        unless parts.size == 6 && Canvas::Security.hmac_sha1(parts[0..-2].join('-'), key) == parts[-1]
          raise BasicLTI::BasicOutcomes::Unauthorized, "Invalid analytics service token"
        end
        user = User.find(parts[1].to_i)
        course = Course.find(parts[2].to_i)
        timestamp = parts[3].to_i
        nonce = parts[4]
        Token.new(tool, user, course, timestamp, nonce)
      end
    end

    def self.create_token(tool, user, course)
      Token.create(tool, user, course).serialize
    end

    def self.log_page_view(token, opts={})
      course = token.course
      user = token.user
      tool = token.tool
      duration = opts[:duration]
      seconds = duration ? Duration.new(duration).to_i : nil

      if seconds

        course.all_enrollments.where(:user_id => user).
          update_all(['total_activity_time = COALESCE(total_activity_time, 0) + ?', seconds])
      end

      AssetUserAccess.log(user, course, code: tool.asset_string, group_code: "external_tools", category: "external_tools")

      if PageView.page_views_enabled?
        PageView.new(user: user, context: course, account: course.account).tap { |p|
          p.request_id = SecureRandom.uuid
          p.url = opts[:url]
          # TODO: override 10m cap?
          p.interaction_seconds = seconds
        }.save
      end
    end
  end
end
