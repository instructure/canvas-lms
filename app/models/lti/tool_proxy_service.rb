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

    def process_tool_proxy_json(json, context, guid)
      tp = IMS::LTI::Models::ToolProxy.new.from_json(json)
      tp.tool_proxy_guid = guid
      tool_proxy = nil
      ToolProxy.transaction do
        product_family = create_product_family(tp, context.root_account)
        tool_proxy = create_tool_proxy(tp, context.root_account, product_family)
        process_resources(tp, tool_proxy)
        create_proxy_binding(tool_proxy, context)
      end
      tool_proxy
    end

    private

    def create_tool_proxy(tp, account, product_family)
      tool_proxy = ToolProxy.new
      tool_proxy.product_family = product_family
      tool_proxy.guid = tp.tool_proxy_guid
      tool_proxy.shared_secret = tp.security_contract.shared_secret
      tool_proxy.product_version = tp.tool_profile.product_instance.product_info.product_version
      tool_proxy.lti_version = tp.tool_profile.lti_version
      tool_proxy.root_account = account.root_account
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
        product_family.vendor_name = tp.tool_profile.product_instance.product_info.product_family.vendor.default_name
        product_family.vendor_description = tp.tool_profile.product_instance.product_info.product_family.vendor.default_description
        product_family.website = tp.tool_profile.product_instance.product_info.product_family.vendor.website
        product_family.vendor_email = tp.tool_profile.product_instance.product_info.product_family.vendor.contact.email
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
      message_handler.resource = resource
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
      tp.tool_profile.resource_handler.each do |rh|
        resource = create_resource_handler(rh, tool_proxy)
        rh.message.each do |mh|
          create_message_handler(mh, tp.tool_profile.base_message_url, resource)
        end
      end
    end

    private

    def create_json(obj)
      obj.kind_of?(Array) ? obj.map(&:as_json) : obj.as_json
    end

  end
end