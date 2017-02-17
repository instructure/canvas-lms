#
# Copyright (C) 2014 Instructure, Inc.
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
#

module Lti
  module Ims
    class ToolConsumerProfileController < ApplicationController
      include Lti::ApiServiceHelper

      before_action :require_context
      skip_before_action :require_user
      skip_before_action :load_user

      def show
        tcp_url = polymorphic_url([@context, :tool_consumer_profile],
                                  tool_consumer_profile_id: Lti::ToolConsumerProfileCreator::TCP_UUID)
        profile = Lti::ToolConsumerProfileCreator.new(@context, tcp_url).create(developer_credentials?)

        render json: profile.to_json, :content_type => 'application/vnd.ims.lti.v2.toolconsumerprofile+json'
      end

      private

      def developer_credentials?
        dev_key = DeveloperKey.find_cached(oauth_consumer_key)
        return oauth_authenticated_request?(dev_key.api_key) if dev_key.present?
        rescue Exception
          return false
      end
    end
  end
end
