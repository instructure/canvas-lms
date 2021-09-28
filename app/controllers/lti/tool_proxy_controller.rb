# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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
    include SupportHelpers::ControllerHelpers

    before_action :require_context
    before_action :require_user
    before_action :set_tool_proxy, only: [:destroy, :update, :accept_update, :dismiss_update, :recreate_subscriptions]
    before_action :require_site_admin, only: [:recreate_subscriptions]

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

    def recreate_subscriptions
      if @tool_proxy.nil? || @tool_proxy.workflow_state != 'active'
        render json: '{"status":"error", "error": "active tool proxy not found"}'
        return
      end

      ToolProxyService.recreate_missing_subscriptions(@tool_proxy)
      render json: '{"status":"success"}'
    end

    private

    def set_tool_proxy
      @tool_proxy = Lti::ToolProxy.find(params[:tool_proxy_id])
    end

    def update_workflow_state(workflow_state)
      Rails.logger.info do
        "in: ToolProxyController::update_workflow_state, tool_id: #{@tool_proxy.id}, "\
        "old state: #{@tool_proxy.workflow_state}, new state: #{workflow_state}"
      end
      @tool_proxy.update_attribute(:workflow_state, workflow_state)

      # destroy or create subscriptions
      ToolProxyService.delete_subscriptions(@tool_proxy) if workflow_state == 'deleted'
      ToolProxyService.recreate_missing_subscriptions(@tool_proxy) if workflow_state == 'active'

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
