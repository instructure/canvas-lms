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
  class PlatformNotificationService
    NOTICE_TYPES = %w[
      LtiHelloWorldNotice
    ].freeze

    def self.subscribe_tool_for_notice(tool:, notice_type:, handler_url:)
      raise ArgumentError, "handler must be a valid URL or an empty string" unless handler_url.match?(URI::DEFAULT_PARSER.make_regexp)

      validate_notice_parameters(tool:, notice_type:, handler_url:)
      destroy_notice_handlers(tool:, notice_type:)
      tool.lti_notice_handlers.create!(
        notice_type:,
        url: handler_url,
        account: tool.account
      )
    end

    def self.unsubscribe_tool_for_notice(tool:, notice_type:)
      validate_notice_parameters(tool:, notice_type:, handler_url: "")
      destroy_notice_handlers(tool:, notice_type:)
    end

    def self.list_handlers(tool:)
      notices_with_handlers = tool
                              .lti_notice_handlers
                              .active
                              .map { |handler| { notice_type: handler.notice_type, handler: handler.url } }
      notices_without_handlers = NOTICE_TYPES - notices_with_handlers.pluck(:notice_type)
      notices_with_handlers + notices_without_handlers.map { |notice_type| { notice_type:, handler: "" } }
    end

    def self.validate_notice_parameters(tool:, notice_type:, handler_url:)
      raise ArgumentError, "unknown notice_type, it must be one of [#{NOTICE_TYPES.join(", ")}]" unless NOTICE_TYPES.include?(notice_type)
      raise ArgumentError, "handler url should match tool's domain" unless handler_url.blank? || tool.matches_host?(handler_url)
    end
    private_class_method :validate_notice_parameters

    def self.destroy_notice_handlers(tool:, notice_type:)
      tool.lti_notice_handlers.active.where(notice_type:).destroy_all
    end
    private_class_method :destroy_notice_handlers
  end
end
