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
  class ToolProxyController < ApplicationController
    before_filter :require_context
    before_filter :require_user
    before_filter :set_tool_proxy, only: [:destroy, :update, :accept_update, :dismiss_update]

    def destroy
      if authorized_action(@context, @current_user, :update)
        update_workflow_state('deleted')
        render json: '{"status":"success"}'
      end
    end

    def update
      if authorized_action(@context, @current_user, :update)
        update_workflow_state(params['workflow_state'])
        render json: '{"status":"success"}'
      end
    end


    def accept_update
      if authorized_action(@context, @current_user, :update)
        success = false

        if @tool_proxy.update?
          ack_url = @tool_proxy.update_payload[:acknowledgement_url]
          payload = @tool_proxy.update_payload[:payload]
          tc_half_shared_secret = @tool_proxy.update_payload[:tc_half_shared_secret]

          guid = @tool_proxy.guid
          tp_service = ToolProxyService.new

          ActiveRecord::Base.transaction do

            tp_service.process_tool_proxy_json(
              json: payload,
              context: context,
              guid: guid,
              tool_proxy_to_update: @tool_proxy,
              tc_half_shared_secret: tc_half_shared_secret
            )

            ack_response = CanvasHttp.put(ack_url)
            if ack_response.code == "200"
              success = true
            else
              # something went terribly wrong
              raise ActiveRecord::Rollback
            end
          end
        end

        if success
          render json: '{"status": "Success"}'
        else
          render json: '{"status": "Failed"}', status: 424
        end
      end
    end

    def dismiss_update
      if authorized_action(@context, @current_user, :update)

        ack_url = @tool_proxy.update_payload[:acknowledgement_url]
        @tool_proxy.update_payload = nil
        @tool_proxy.save!

        CanvasHttp.delete(ack_url)
        render json: '{"status":"success"}'
      end
    end

    private

    def set_tool_proxy
      @tool_proxy = Lti::ToolProxy.find(params[:tool_proxy_id])
    end

    def update_workflow_state(workflow_state)
      @tool_proxy.update_attribute(:workflow_state, workflow_state)

      # this needs to be moved to whatever changes the workflow state to active
      invalidate_nav_tabs_cache(@tool_proxy)
    end

    def invalidate_nav_tabs_cache(tool_proxy)
      placements = Set.new

      tool_proxy.resources.each do |resource_handler|
        placements.merge(resource_handler.placements.map(&:placement))
      end

      unless (placements & [ResourcePlacement::COURSE_NAVIGATION, ResourcePlacement::ACCOUNT_NAVIGATION]).blank?
        Lti::NavigationCache.new(@domain_root_account).invalidate_cache_key
      end
    end

  end
end
