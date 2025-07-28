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
    module_function

    class InvalidNoticeHandler < StandardError; end

    def subscribe_tool_for_notice(tool:, notice_type:, handler_url:, max_batch_size:)
      validate_notice_type!(notice_type)
      handler = tool.lti_notice_handlers.new(
        notice_type:,
        url: handler_url,
        account: tool.related_account,
        max_batch_size:
      )

      begin
        handler.validate!
      rescue ActiveRecord::RecordInvalid => e
        raise InvalidNoticeHandler, e.message
      end

      destroy_notice_handlers(tool:, notice_type:)
      handler.save!

      if notice_type == Lti::Pns::NoticeTypes::HELLO_WORLD
        send_notices(notice_handler: handler, builders: [Lti::Pns::LtiHelloWorldNoticeBuilder.new])
      end
      handler_api_json(handler:)
    end

    def unsubscribe_tool_for_notice(tool:, notice_type:)
      validate_notice_type!(notice_type)
      destroy_notice_handlers(tool:, notice_type:)
      empty_api_json(notice_type:)
    end

    # @return [Array<Hash>] list of notice handlers for the tool in api format
    def list_handlers(tool:)
      found_notice_handlers = tool.lti_notice_handlers.active.map do |handler|
        handler_api_json(handler:)
      end
      types_without_handlers = Lti::Pns::NoticeTypes::ALL - found_notice_handlers.pluck(:notice_type)
      found_notice_handlers + types_without_handlers.map do |notice_type|
        empty_api_json(notice_type:)
      end
    end

    def handler_api_json(handler:)
      { notice_type: handler.notice_type, handler: handler.url, max_batch_size: handler.max_batch_size }.compact
    end

    def empty_api_json(notice_type:)
      { notice_type:, handler: "" }
    end

    def notify_tools_in_account(account, *builders)
      notice_type = get_notice_type(builders:)
      Lti::NoticeHandler.active.where(notice_type:, account:).find_each do |notice_handler|
        send_notices(notice_handler:, builders:)
      end
    end

    def notify_tools_in_course(course, *builders)
      tool_ids = Lti::ContextToolFinder.all_tools_for(course).ids
      notify_tools(cet_id_or_ids: tool_ids, builders:)
    end

    def notify_tools(cet_id_or_ids:, builders:)
      notice_type = get_notice_type(builders:)
      Lti::NoticeHandler.active.where(notice_type:, context_external_tool_id: cet_id_or_ids).find_each do |notice_handler|
        send_notices(notice_handler:, builders:)
      end
    end

    def notify_asset_processor(asset_processor, *builders)
      notice_type = get_notice_type(builders:)
      Lti::NoticeHandler.active.where(notice_type:, context_external_tool_id: asset_processor.context_external_tool_id).find_each do |notice_handler|
        send_notices(notice_handler:, builders:)
      end
    end

    def validate_notice_type!(notice_type)
      # This is also validated in the model, but we want to validate for
      # unsubscribing and have a consistent error also for subscribing
      unless Lti::Pns::NoticeTypes::ALL.include?(notice_type)
        raise InvalidNoticeHandler, "Validation failed: Notice type unknown, must be one of [#{Lti::Pns::NoticeTypes::ALL.join(", ")}]"
      end
    end
    private_class_method :validate_notice_type!

    def send_notices(notice_handler:, builders:)
      builders.each_slice(notice_handler.max_batch_size || builders.length) do |batch|
        send_notice_batch(notice_handler:, builders: batch)
      end
    end
    private_class_method :send_notices

    def send_notice_batch(notice_handler:, builders:)
      tool = notice_handler.context_external_tool
      global_id = generate_notification_uuid
      notice_objects = builders.map { |builder| builder.build(tool) }
      webhook_body = { notices: notice_objects }.to_json

      if Rails.env.development? && !Services::NotificationService.configured?
        CanvasHttp
          .delay(strand: "lti_platform_notification_service_development")
          .post(notice_handler.url, body: webhook_body, content_type: "application/json")
      else
        Services::NotificationService.process(
          global_id,
          webhook_body,
          "webhook",
          { url: notice_handler.url }.to_json
        )
      end
    end
    private_class_method :send_notice_batch

    def get_notice_type(builders:)
      notice_types = builders.map(&:notice_type).uniq
      raise ArgumentError, "builders must have the same notice_type" unless notice_types.length == 1

      notice_types.first
    end
    private_class_method :get_notice_type

    def generate_notification_uuid
      "pns-notify/#{SecureRandom.uuid}"
    end
    private_class_method :generate_notification_uuid

    def destroy_notice_handlers(tool:, notice_type:)
      tool.lti_notice_handlers.active.where(notice_type:).destroy_all
    end
    private_class_method :destroy_notice_handlers
  end
end
