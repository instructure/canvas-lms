# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

module Twitter
  class Messenger
    attr_reader :message
    attr_reader :host
    attr_reader :id

    def initialize(message, twitter_service, host, id)
      @message = message
      @twitter_service = twitter_service
      @host = host
      @id = id
    end

    def deliver
      return unless @twitter_service
      twitter = Twitter::Connection.from_service_token(
        @twitter_service.token,
        @twitter_service.secret
      )
      twitter.send_direct_message(
        @twitter_service.service_user_name,
        @twitter_service.service_user_id,
        "#{body}"
      )
    end

    def url
      message.main_link || message.url || "http://#{host}/mr/#{id}"
    end

    def body
      truncated_body = HtmlTextHelper.strip_and_truncate(message.body, :max_length => (139 - url.length))
      "#{truncated_body} #{url}"
    end
  end
end
