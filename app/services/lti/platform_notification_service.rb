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

module Lti
  module PlatformNotificationService
    NOTICE_TYPES = %w[
      LtiHelloWorldNotice
    ].freeze

    module_function

    def subscribe_tool_for_notice(tool:, notice_type:, handler_url:)
      raise ArgumentError, "handler must be a valid URL or an empty string" unless handler_url.match?(URI::DEFAULT_PARSER.make_regexp)

      validate_notice_parameters(tool:, notice_type:, handler_url:)
      destroy_notice_handlers(tool:, notice_type:)
      handler = tool.lti_notice_handlers.create!(
        notice_type:,
        url: handler_url,
        account: tool.account
      )
      handler_api_json(handler:)
    end

    def unsubscribe_tool_for_notice(tool:, notice_type:)
      validate_notice_parameters(tool:, notice_type:, handler_url: "")
      destroy_notice_handlers(tool:, notice_type:)
      empty_api_json(notice_type:)
    end

    # @return [Array<Hash>] list of notice handlers for the tool in api format
    def list_handlers(tool:)
      found_notice_handlers = tool.lti_notice_handlers.active.map do |handler|
        handler_api_json(handler:)
      end
      types_without_handlers = NOTICE_TYPES - found_notice_handlers.pluck(:notice_type)
      found_notice_handlers + types_without_handlers.map do |notice_type|
        empty_api_json(notice_type:)
      end
    end

    def handler_api_json(handler:)
      { notice_type: handler.notice_type, handler: handler.url }
    end

    def empty_api_json(notice_type:)
      { notice_type:, handler: "" }
    end

    def validate_notice_parameters(tool:, notice_type:, handler_url:)
      raise ArgumentError, "unknown notice_type, it must be one of [#{NOTICE_TYPES.join(", ")}]" unless NOTICE_TYPES.include?(notice_type)
      raise ArgumentError, "handler url should match tool's domain" unless handler_url.blank? || tool.matches_host?(handler_url)
    end
    private_class_method :validate_notice_parameters

    def destroy_notice_handlers(tool:, notice_type:)
      tool.lti_notice_handlers.active.where(notice_type:).destroy_all
    end
    private_class_method :destroy_notice_handlers
  end
end
