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

module Lti::IMS
  # @API Notice Handlers
  #
  # API for the LTI Platform Notification Service.
  #
  # Requires LTI Advantage (JWT OAuth2) tokens with the
  # `https://purl.imsglobal.org/spec/lti/scope/noticehandlers` scope.
  #
  # See the Canvas
  # <a href="/doc/api/file.pns.html">Platform Notification Service</a>
  # intro guide for an overview of these endpoints and information on specific
  # notice types.
  #
  # @model NoticeCatalog
  #     {
  #       "id": "NoticeCatalog",
  #       "description": "Set of notice handlers (one per notice type) for an LTI tool deployment.",
  #       "properties": {
  #          "client_id": {
  #            "description": "The LTI tool's client ID (global developer key ID)",
  #            "example": "10000000000001",
  #            "type": "string"
  #          },
  #          "deployment_id": {
  #            "description": "String that identifies the Platform-Tool integration governing the notices",
  #            "example": "123:8865aa05b4b79b64a91a86042e43af5ea8ae79eb",
  #            "type": "string"
  #          },
  #          "notice_handlers": {
  #            "type": "array",
  #            "description": "List of notice handlers for the tool",
  #            "items": { "$ref": "NoticeHandler" },
  #            "example": [
  #              {
  #                "handler": "",
  #                "notice_type": "LtiHelloWorldNotice"
  #              }
  #            ]
  #          }
  #       }
  #     }
  #
  # @model NoticeHandler
  #     {
  #       "id": "NoticeHandler",
  #       "description": "A notice handler for a particular tool deployment and notice type.",
  #       "properties": {
  #         "handler": {
  #           "description": "URL to receive the notice",
  #           "example": "https://example.com/notice_handler",
  #           "type": "string"
  #         },
  #         "notice_type": {
  #           "description": "The type of notice",
  #           "example": "LtiHelloWorldNotice",
  #           "type": "string"
  #         },
  #         "max_batch_size": {
  #           "description": "The maximum number of notices to include in a single batch, or 'null' if not set.",
  #           "example": 100,
  #           "type": "integer"
  #         }
  #       }
  #     }
  #
  class NoticeHandlersController < ApplicationController
    include Concerns::AdvantageServices

    before_action :validate_tool_id

    # @API Show notice handlers
    # List all notice handlers for the tool
    #
    # @returns NoticeCatalog
    #
    # @example_response
    #   {
    #     "client_id": 10000000000267,
    #     "deployment_id": "123:8865aa05b4b79b64a91a86042e43af5ea8ae79eb",
    #     "notice_handlers": [
    #       {
    #         "handler": "",
    #         "notice_type": "LtiHelloWorldNotice"
    #       }
    #     ]
    #   }
    #
    def index
      handlers = Lti::PlatformNotificationService.list_handlers(tool:)
      render json: {
        client_id: developer_key.global_id,
        deployment_id: tool.deployment_id,
        notice_handlers: handlers
      }
    end

    # @API Set notice handler
    # Subscribe (set) or unsubscribe (remove) a notice handler for the tool
    #
    # @argument notice_type [Required, String]
    #   The type of notice
    # @argument handler [Required, String]
    #   URL to receive the notice, or an empty string to unsubscribe
    # @argument max_batch_size [Optional, Integer]
    #   The maximum number of notices to include in a single batch
    #
    # @returns NoticeHandler
    #
    # @example_response
    #   {
    #       "handler": "",
    #       "notice_type": "LtiHelloWorldNotice"
    #   }
    #
    def update
      notice_type = params.require(:notice_type)
      handler_url = params[:handler]
      handler_json =
        if handler_url.present?
          Lti::PlatformNotificationService.subscribe_tool_for_notice(
            tool:,
            notice_type:,
            handler_url:,
            max_batch_size: params[:max_batch_size]
          )
        elsif handler_url == ""
          Lti::PlatformNotificationService.unsubscribe_tool_for_notice(tool:, notice_type:)
        else
          return render_error("handler must be a valid URL or an empty string", :bad_request)
        end

      render json: handler_json
    rescue Lti::PlatformNotificationService::InvalidNoticeHandler => e
      logger.warn "Invalid PNS notice_handler subscription request: #{e.inspect}"
      render_error(e.message, :bad_request)
    end

    private

    def validate_tool_id
      unless tool.developer_key_id == developer_key.id
        render_error("permission denied", :forbidden)
      end
    end

    def scopes_matcher
      self.class.all_of(TokenScopes::LTI_PNS_SCOPE)
    end

    def context
      tool.context
    end

    def tool
      @tool ||= Lti::ToolFinder.find(params.require(:context_external_tool_id), scope: ContextExternalTool.active)
    rescue ActiveRecord::RecordNotFound
      render_error("not found", :not_found)
    end
  end
end
