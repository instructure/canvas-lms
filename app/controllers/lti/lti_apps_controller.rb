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

    def index
      if authorized_action(@context, @current_user, :update)
        app_collator = AppCollator.new(@context)
        collection = app_collator.bookmarked_collection

        respond_to do |format|
          app_defs = Api.paginate(collection, self, named_context_url(@context, :api_v1_context_app_definitions_url, include_host: true))
          format.json {render json: app_collator.app_definitions(app_defs)}
        end
      end
    end

    def launch_definitions
      if authorized_action(@context, @current_user, :update)
        placements = params['placements'] || []
        collection = AppLaunchCollator.bookmarked_collection(@context, placements)

        respond_to do |format|
          launch_defs = Api.paginate(collection, self, named_context_url(@context, :api_v1_context_launch_definitions_url, include_host: true))
          format.json { render :json => AppLaunchCollator.launch_definitions(launch_defs, placements) }
        end
      end
    end

  end
end