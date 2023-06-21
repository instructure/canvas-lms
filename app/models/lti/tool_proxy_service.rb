# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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
require "ims/lti"

module Lti
  class ToolProxyService
    attr_reader :tc_half_secret

    def process_tool_proxy_json(json:, context:, guid:, tool_proxy_to_update: nil, tc_half_shared_secret: nil, developer_key: nil, registration_url: nil)
      @tc_half_secret = tc_half_shared_secret
      tp = ::IMS::LTI::Models::ToolProxy.new.from_json(json)
      tp.tool_proxy_guid = guid
      tcp_uuid = tp.tool_consumer_profile&.match(%r{tool_consumer_profile/([a-fA-f0-9-]+)})&.captures&.first
      tcp_uuid ||= developer_key&.tool_consumer_profile&.uuid
      tcp_uuid ||= Lti::ToolConsumerProfile::DEFAULT_TCP_UUID
      begin
        tcp = Lti::ToolConsumerProfileCreator.new(
          context,
          tp.tool_consumer_profile,
          developer_key:,
          tcp_uuid:
        ).create
        ToolProxyValidator.new(tool_proxy: tp, tool_consumer_profile: tcp).validate!
      rescue Lti::Errors::InvalidToolProxyError
        raise unless deprecated_split_secret?(tp)
      end
      tool_proxy = nil
      ToolProxy.transaction do
        product_family = create_product_family(tp, context.root_account, developer_key)
        tool_proxy = create_tool_proxy(tp:,
                                       context:,
                                       product_family:,
                                       tool_proxy:
                                       tool_proxy_to_update,
                                       registration_url:,
                                       developer_key:)
        process_resources(tp, tool_proxy)
        create_proxy_binding(tool_proxy, context)
        create_or_update_tool_settings(tp, tool_proxy)
      end

      tool_proxy.reload
    end

    def create_secret(tp)
      security_contract = tp.security_contract
      tp_half_secret = security_contract.tp_half_shared_secret
      if tp.enabled_capabilities.intersect?(["OAuth.splitSecret", "Security.splitSecret"]) && tp_half_secret.present?
        @tc_half_secret ||= SecureRandom.hex(64)
        tc_half_secret + tp_half_secret
      else
        security_contract.shared_secret
      end
    end

    private

    def developer_key_mismatch?(tool_proxy, developer_key)
      installing_vendor = tool_proxy&.tool_profile&.product_instance&.product_info&.product_family&.vendor&.code
      return true if installing_vendor.blank?

      vendor_dev_keys = DeveloperKey.by_cached_vendor_code(installing_vendor)
      return false if developer_key.blank? && vendor_dev_keys.blank?

      !vendor_dev_keys.include?(developer_key)
    end

    def deprecated_split_secret?(tp)
      tp.enabled_capability.present? &&
        tp.enabled_capability.include?("OAuth.splitSecret") &&
        tp.security_contract.tp_half_shared_secret.present?
    end

    def create_tool_proxy(tp:, context:, product_family:, tool_proxy: nil, registration_url:, developer_key: nil)
      # make sure the guid never changes
      raise Lti::Errors::InvalidToolProxyError if tool_proxy && tp.tool_proxy_guid != tool_proxy.guid
      raise Errors::InvalidToolProxyError, "Developer key mismatch" if developer_key_mismatch?(tp, developer_key)

      tool_proxy ||= ToolProxy.new
      tool_proxy.registration_url = registration_url
      tool_proxy.product_family = product_family
      tool_proxy.guid = tp.tool_proxy_guid
      tool_proxy.shared_secret = create_secret(tp)
      tool_proxy.product_version = tp.tool_profile.product_instance.product_info.product_version
      tool_proxy.lti_version = tp.tool_profile.lti_version
      tool_proxy.name = tp.tool_profile.product_instance.product_info.default_name
      tool_proxy.description = tp.tool_profile.product_instance.product_info.default_description
      tool_proxy.context = context
      tool_proxy.workflow_state ||= "disabled"
      tool_proxy.raw_data = tp.as_json
      tool_proxy.update_payload = nil
      tool_proxy.save!
      tool_proxy
    end

    def create_product_family(tp, account, developer_key)
      vendor_code = tp.tool_profile.product_instance.product_info.product_family.vendor.code
      product_code = tp.tool_profile.product_instance.product_info.product_family.code
      unless (product_family = ProductFamily.where(vendor_code:, product_code:, developer_key:).first)
        product_family = ProductFamily.new
        product_family.vendor_code = vendor_code
        product_family.product_code = product_code
        product_family.developer_key = developer_key

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
      message_handler = resource.message_handlers.where(message_type: mh.message_type).first_or_create! do |m|
        m.launch_path = "#{base_path}#{mh.path}"
        m.capabilities = create_json(mh.enabled_capability)
        m.parameters = create_json(mh.parameter.as_json)
        m.tool_proxy = resource.tool_proxy
      end
      create_placements(mh, message_handler)
    end

    def create_resource_handler(rh, tool_proxy)
      tool_proxy.resources.where(resource_type_code: rh.resource_type.code).first_or_create! do |r|
        r.name = rh.default_name
        r.description = rh.default_description
        r.icon_info = create_json(rh.icon_info)
      end
    end

    def create_proxy_binding(tool_proxy, context)
      ToolProxyBinding.where(context_id: context,
                             context_type: context.class.to_s,
                             tool_proxy_id: tool_proxy).first_or_create!
    end

    def process_resources(tp, tool_proxy)
      resource_handlers = tp.tool_profile.resource_handlers
      if tp.tool_profile.messages.present?
        product_name = tp.tool_profile.product_instance.product_info.product_name
        r = ::IMS::LTI::Models::ResourceHandler.new.from_json(
          {
            resource_type: { code: "instructure.com:default" },
            resource_name: product_name
          }.to_json
        )
        r.message = tp.tool_profile.messages
        resource_handlers << r
      end

      resource_type_codes = resource_handlers.map { |s| s.resource_type.code }
      tool_proxy.resources.each do |resource|
        resource.destroy unless resource_type_codes.include? resource.resource_type_code
      end

      resource_handlers.each do |rh|
        resource_handler = create_resource_handler(rh, tool_proxy)

        message_types = rh.messages.map(&:message_type)
        resource_handler.message_handlers.each do |message|
          message.destroy unless message_types.include? message.message_type
        end

        rh.messages.each do |mh|
          create_message_handler(mh, tp.tool_profile.base_message_url, resource_handler)
        end
      end
    end

    def create_placements(mh, message_handler)
      message_handler.placements.each do |placement|
        placement.destroy unless ResourcePlacement::LEGACY_DEFAULT_PLACEMENTS.include? placement.placement
      end

      if mh.enabled_capabilities.intersect?(ResourcePlacement::PLACEMENT_LOOKUP.keys)

        mhp = mh.enabled_capability.map { |p| ResourcePlacement::PLACEMENT_LOOKUP[p] }
        message_handler.placements.each do |placement|
          placement.destroy unless mhp.include? placement.placement
        end

        mhp.each do |p|
          message_handler.placements.where(placement: p).first_or_create! if p
        end
      else
        ResourcePlacement::LEGACY_DEFAULT_PLACEMENTS.each do |p|
          message_handler.placements.where(placement: p).first_or_create!
        end
      end
    end

    def create_or_update_tool_settings(tp, tool_proxy)
      if tp.custom.present?
        tool_setting = ToolSetting.where(tool_proxy:).first_or_create!
        custom = tool_setting.custom || {}
        tool_setting.update(custom: custom.merge(tp.custom))
      end
    end

    def create_json(obj)
      obj.is_a?(Array) ? obj.map(&:as_json) : obj.as_json
    end
  end
end
