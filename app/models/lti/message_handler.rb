# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
  class MessageHandler < ActiveRecord::Base
    BASIC_LTI_LAUNCH_REQUEST = "basic-lti-launch-request"
    TOOL_PROXY_REREGISTRATION_REQUEST = "ToolProxyRegistrationRequest"

    attr_readonly :created_at

    belongs_to :resource_handler, class_name: "Lti::ResourceHandler"
    belongs_to :tool_proxy, class_name: "Lti::ToolProxy"

    has_many :placements, class_name: "Lti::ResourcePlacement", dependent: :destroy
    has_many :context_module_tags, -> { where("content_tags.tag_type='context_module' AND content_tags.workflow_state<>'deleted'").preload(context_module: :content_tags) }, as: :content, inverse_of: :content, class_name: "ContentTag"

    serialize :capabilities
    serialize :parameters

    validates :message_type, :resource_handler, :launch_path, presence: true

    scope :by_message_types, ->(*message_types) { where(message_type: message_types) }

    scope :for_context, lambda { |context|
      tool_proxies = ToolProxy.find_active_proxies_for_context(context)
      joins(:resource_handler).where(lti_resource_handlers: { tool_proxy_id: tool_proxies })
    }

    scope :has_placements, lambda { |*placements|
      where(Lti::ResourcePlacement.where(placement: placements)
                .where("lti_message_handlers.id = lti_resource_placements.message_handler_id")
                .arel.exists)
    }

    def self.lti_apps_tabs(context, placements, _opts)
      apps = Lti::MessageHandler.for_context(context)
                                .has_placements(*placements)
                                .by_message_types(Lti::MessageHandler::BASIC_LTI_LAUNCH_REQUEST).to_a

      launch_path_helper = case context
                           when Course
                             :course_basic_lti_launch_request_path
                           when Account
                             :account_basic_lti_launch_request_path
                           end
      apps.sort_by(&:id).map do |app|
        args = { message_handler_id: app.id, resource_link_fragment: "nav" }
        args[:"#{context.class.name.downcase}_id"] = context.id
        {
          id: app.asset_string,
          label: app.resource_handler.name,
          css_class: app.asset_string,
          href: launch_path_helper,
          visibility: nil,
          external: true,
          hidden: false,
          args:
        }
      end
    end

    def self.by_resource_codes(vendor_code:, product_code:, resource_type_code:, context:, message_type: BASIC_LTI_LAUNCH_REQUEST)
      possible_handlers = ResourceHandler.by_resource_codes(vendor_code:,
                                                            product_code:,
                                                            resource_type_code:,
                                                            context:)
      resource_handler = nil
      search_contexts = context.account_chain.dup.unshift(context)
      search_contexts.each do |search_context|
        break if resource_handler.present?

        resource_handler = possible_handlers.find { |rh| rh.tool_proxy.context == search_context }
      end
      resource_handler&.find_message_by_type(message_type)
    end

    def valid_resource_url?(resource_url)
      URI.parse(resource_url).host == URI.parse(launch_path).host
    end

    def build_resource_link_id(context:, link_fragment: nil)
      resource_link_id = "#{context.class}_#{context.global_id},MessageHandler_#{global_id}"
      resource_link_id += ",#{link_fragment}" if link_fragment
      Canvas::Security.hmac_sha1(resource_link_id)
    end

    def resource_codes
      resource_handler.tool_proxy.resource_codes.merge(
        { resource_type_code: resource_handler.resource_type_code }
      )
    end
  end
end
