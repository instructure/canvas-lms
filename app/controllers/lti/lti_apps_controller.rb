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
  class LtiAppsController < ApplicationController
    before_filter :require_context
    before_filter :require_user

    def launch_definitions
      if authorized_action(@context, @current_user, :update)
        placements = params['placements'] || []
        collection = AppCollator.bookmarked_collection(@context, placements)

        respond_to do |format|
          launch_defs = Api.paginate(collection, self, launch_definitions_url)
          format.json { render :json => AppCollator.launch_definitions(launch_defs, placements) }
        end
      end
    end


    private

    def launch_definitions_url
      if @context.is_a? Course
        api_v1_course_launch_definitions_url(@context)
      else
        api_v1_account_launch_definitions_url(@context)
      end
    end


  end
end