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
  class ToolConsumerProfileController < ApplicationController
    before_filter :require_context
    skip_before_filter :require_user
    skip_before_filter :load_user

    def show
      uuid = "339b6700-e4cb-47c5-a54f-3ee0064921a9" #Hard coded until we start persisting the tcp
      profile = Lti::ToolConsumerProfileCreator.new(@context, tool_consumer_profile_url(uuid)).create
      render json: profile.to_json, :content_type => 'application/vnd.ims.lti.v2.toolconsumerprofile+json'
    end

    private

    def tool_consumer_profile_url(uuid)
      case context
        when Course
          course_tool_consumer_profile_url(context)
        when Account
          account_tool_consumer_profile_url(context)
        else
          raise "Unsupported context"
      end
    end

  end
end