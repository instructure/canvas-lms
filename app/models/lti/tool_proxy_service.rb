#
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
  class ToolProxyService

    class InvalidToolProxyError < RuntimeError

      def initialize(message = nil, json = {})
        super(message)
        @message = message
        @json = json
      end

      def to_json
        @json[:error] = @message if @message
        @json.to_json
      end

    end

    def process_tool_proxy_json(json, context, guid)
      tp = IMS::LTI::Models::ToolProxy.new.from_json(json)
      tp.tool_proxy_guid = guid
      validate_proxy!(tp)
      tool_proxy = nil
      ToolProxy.transaction do
        product_family = create_product_family(tp, context.root_account)
        tool_proxy = create_tool_proxy(tp, context, product_family)
        process_resources(tp, tool_proxy)
        create_proxy_binding(tool_proxy, context)
        create_tool_settings(tp, tool_proxy)
      end
      tool_proxy
    end

    private

    def create_tool_proxy(tp, context, product_family)
      tool_proxy = ToolProxy.new
      tool_proxy.product_family = product_family
      tool_proxy.guid = tp.tool_proxy_guid
      tool_proxy.shared_secret = tp.security_contract.shared_secret
      tool_proxy.product_version = tp.tool_profile.product_instance.product_info.product_version
      tool_proxy.lti_version = tp.tool_profile.lti_version
      tool_proxy.name = tp.tool_profile.product_instance.product_info.default_name
      tool_proxy.description = tp.tool_profile.product_instance.product_info.default_description
      tool_proxy.context = context
      tool_proxy.workflow_state = 'disabled'
      tool_proxy.raw_data = tp.as_json
      tool_proxy.save!
      tool_proxy
    end

    def create_product_family(tp, account)
      vendor_code = tp.tool_profile.product_instance.product_info.product_family.vendor.code
      product_code = tp.tool_profile.product_instance.product_info.product_family.code
      unless product_family = ProductFamily.where(vendor_code: vendor_code, product_code: product_code).first
        product_family = ProductFamily.new
        product_family.vendor_code = vendor_code
        product_family.product_code = product_code

        vendor = tp.tool_profile.product_instance.product_info.product_family.vendor
        product_family.vendor_name = vendor.default_name
        product_family.vendor_description = vendor.default_description
        product_family.website = vendor.website
        product_family.vendor_email = vendor.contact.email if vendor.contact

        product_family.root_account = account.root_account
        product_family.save!
      end
      product_family
    end

    def create_message_handler(mh, base_path, resource)
      message_handler = MessageHandler.new
      message_handler.message_type = mh.message_type
      message_handler.launch_path = "#{base_path}#{mh.path}"
      message_handler.capabilities = create_json(mh.enabled_capability)
      message_handler.parameters = create_json(mh.parameter.as_json)
      message_handler.resource_handler = resource
      message_handler.save!
      message_handler
    end

    def create_resource_handler(rh, tool_proxy)
      resource_handler = ResourceHandler.new
      resource_handler.resource_type_code = rh.resource_type.code
      resource_handler.name = rh.default_name
      resource_handler.description = rh.default_description
      resource_handler.icon_info = create_json(rh.icon_info)
      resource_handler.tool_proxy = tool_proxy
      resource_handler.save!

      resource_handler
    end

    def create_proxy_binding(tool_proxy, context)
      binding = ToolProxyBinding.new
      binding.context = context
      binding.tool_proxy = tool_proxy
      binding.save!
      binding
    end

    def process_resources(tp, tool_proxy)
      resource_handlers = tp.tool_profile.resource_handlers
      if tp.tool_profile.messages.present?
        product_name = tp.tool_profile.product_instance.product_info.product_name
        rh = IMS::LTI::Models::ResourceHandler.new.from_json(
          {
            resource_type: {code: 'instructure.com:default'},
            resource_name: product_name
          }.to_json
        )
        rh.message = tp.tool_profile.messages
        resource_handlers << rh
      end

      resource_handlers.each do |rh|
        resource_handler = create_resource_handler(rh, tool_proxy)
        create_placements(rh, resource_handler)
        rh.messages.each do |mh|
          create_message_handler(mh, tp.tool_profile.base_message_url, resource_handler)
        end

      end
    end

    def create_placements(rh, resource_handler)
      if rh.ext_placements
        rh.ext_placements.each do |p|
          if placement = ResourcePlacement::PLACEMENT_LOOKUP[p]
            resource_handler.placements.create(placement: placement)
          end
        end
      else
        ResourcePlacement::DEFAULT_PLACEMENTS.each { |p| resource_handler.placements.create(placement: p) }
      end
    end

    def create_tool_settings(tp, tool_proxy)
      ToolSetting.create!(tool_proxy:tool_proxy, custom: tp.custom) if tp.custom.present?
    end

    def create_json(obj)
      obj.kind_of?(Array) ? obj.map(&:as_json) : obj.as_json
    end

    def validate_proxy!(tp)
      tp_errors = [validate_services(tp), validate_capabilities(tp), validate_security_contract(tp)].compact
      unless tp_errors.flatten.compact.empty?
        json = {}
        messages = []
        tp_errors.each do |e|
          messages << e[0]
          json.merge! e[1]
        end
        last_message = messages.pop if messages.size > 1
        message = "Invalid #{messages.join(', ')}"
        message + " and #{last_message}" if last_message
        raise InvalidToolProxyError.new(message, json)
      end

    end

    def validate_services(tp)
      allowed_services = ToolConsumerProfileCreator::SERVICES.each_with_object({}) { |s, h| h[s[:id]] = s[:action] }
      invalid_services = []
      tp.security_contract.services.each do |service|
        id = service.service.split('#').last
        invalid_actions = service.actions - (allowed_services[id] || [])
        invalid_services << {id: id, actions: invalid_actions} if invalid_actions.present?
      end
      ['Services', invalid_services: invalid_services] unless invalid_services.empty?
    end

    def validate_capabilities(tp)
      requested_caps = []
      tp.tool_profile.resource_handlers.each do |rh|
        rh.messages.each do |mh|
          requested_caps.push(*mh.enabled_capabilities)
          mh.parameters.each { |p| requested_caps << p.variable unless p.fixed? }
        end
      end
      invalid_capabilites = requested_caps - ToolConsumerProfileCreator::CAPABILITIES
      ['Capabilities', invalid_capabilities: invalid_capabilites] unless invalid_capabilites.empty?
    end

    def validate_security_contract(tp)
      invalid_fields = []
      invalid_fields << :shared_secret if tp.security_contract.shared_secret.blank?
      ['SecurityContract', invalid_security_contract: invalid_fields] unless invalid_fields.empty?
    end

  end
end