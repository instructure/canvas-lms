#
# Copyright (C) 2012 Instructure, Inc.
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

# @API Tabs
# @object Tab
#       {
#         "html_url": "/courses/1/external_tools/4",
#         "id": "context_external_tool_4",
#         "label": "WordPress",
#         "type": "external"
#       }

class TabsController < ApplicationController
  include Api::V1::Tab

  before_filter :require_context

  # @API List available tabs for a course or group
  #
  # Returns a list of navigation tabs available in the current context.
  #
  # @argument include[] [String, "external"]
  #   Optionally include external tool tabs in the returned list of tabs
  #   (Only has effect for courses, not groups)
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \ 
  #          https://<canvas>/api/v1/courses/<course_id>/tabs\?include\="external"
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \ 
  #          https://<canvas>/api/v1/groups/<group_id>/tabs"
  #
  # @example_response
  #     [
  #       {
  #         "html_url": "/courses/1",
  #         "id": "home",
  #         "label": "Home",
  #         "type": "internal"
  #       },
  #       {
  #         "html_url": "/courses/1/external_tools/4",
  #         "id": "context_external_tool_4",
  #         "label": "WordPress",
  #         "type": "external"
  #       },
  #       {
  #         "html_url": "/courses/1/grades",
  #         "id": "grades",
  #         "label": "Grades",
  #         "type": "internal"
  #       }
  #     ]
  def index
    if authorized_action(@context, @current_user, :read)
      includes = Array(params[:include])
      tabs = @context.tabs_available(@current_user, :include_external => includes.include?('external'))
      tabs = tabs.select do |tab|
        if (tab[:id] == @context.class::TAB_CHAT rescue false)
          tab[:href] && tab[:label] && feature_enabled?(:tinychat)
        elsif (tab[:id] == @context.class::TAB_COLLABORATIONS rescue false)
          tab[:href] && tab[:label] && Collaboration.any_collaborations_configured?
        elsif (tab[:id] == @context.class::TAB_CONFERENCES rescue false)
          tab[:href] && tab[:label] && feature_enabled?(:web_conferences)
        else
          tab[:href] && tab[:label]
        end
      end
      render :json => tabs_available_json(tabs, @current_user, session)
    end
  end

end
