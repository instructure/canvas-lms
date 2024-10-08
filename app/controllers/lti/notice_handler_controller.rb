# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

# @API Lti Platform Notification Service
#
# Expose API to support LTI Platform Notification Service feature

module Lti
  class NoticeHandlerController < ApplicationController
    include ::Lti::IMS::Concerns::LtiServices
    include Api::V1::DeveloperKey

    before_action :require_feature_enabled
    before_action :validate_tool_id

    def index
      handlers = Lti::PlatformNotificationService.list_handlers(tool:)
      render json: {
        client_id: developer_key.global_id,
        deployment_id: tool.deployment_id,
        notice_handlers: handlers
      }
    end

    def update
      notice_type = params.require(:notice_type)
      handler_url = params[:handler]
      if handler_url.present?
        Lti::PlatformNotificationService.subscribe_tool_for_notice(
          tool:,
          notice_type:,
          handler_url:
        )
      elsif handler_url == ""
        Lti::PlatformNotificationService.unsubscribe_tool_for_notice(
          tool:,
          notice_type:
        )
      else
        raise ArgumentError, "handler must be a valid URL or an empty string"
      end
      index
    rescue ArgumentError => e
      logger.warn "Invalid PNS notice_handler subscription request: #{e.inspect}"
      render_error(e.message, :bad_request)
    end

    private

    def require_feature_enabled
      unless tool.root_account.feature_enabled?(:platform_notification_service)
        render_error("not found", :not_found)
      end
    end

    def validate_tool_id
      unless tool.developer_key_id == developer_key.id
        render_error("permission denied", :forbidden)
      end
    end

    def scopes_matcher
      self.class.all_of(TokenScopes::LTI_PNS_SCOPE)
    end

    def tool
      @tool ||= ContextExternalTool.find(params.require(:context_external_tool_id))
    rescue ActiveRecord::RecordNotFound
      render_error("not found", :not_found)
    end
  end
end
