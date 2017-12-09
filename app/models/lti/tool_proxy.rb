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
  class ToolProxy < ActiveRecord::Base

    has_many :bindings, class_name: 'Lti::ToolProxyBinding', dependent: :destroy
    has_many :resources, class_name: 'Lti::ResourceHandler', dependent: :destroy
    has_many :tool_settings, class_name: 'Lti::ToolSetting', dependent: :destroy
    has_many :message_handlers, class_name: 'Lti::MessageHandler'

    belongs_to :context, polymorphic: [:course, :account]
    belongs_to :product_family, class_name: 'Lti::ProductFamily'

    scope :active, -> { where("lti_tool_proxies.workflow_state = ?", 'active') }

    serialize :raw_data
    serialize :update_payload

    validates_presence_of :shared_secret, :guid, :product_version, :lti_version, :product_family_id, :workflow_state, :raw_data, :context
    validates_uniqueness_of :guid
    validates_inclusion_of :workflow_state, in: ['active', 'deleted', 'disabled']

    def active_in_context?(context)
      self.class.find_active_proxies_for_context(context).include?(self)
    end

    def self.find_active_proxies_for_context_by_vendor_code_and_product_code(context:, vendor_code:, product_code:)
      find_active_proxies_for_context(context)
        .eager_load(:product_family)
        .where('lti_product_families.vendor_code = ? AND lti_product_families.product_code = ?', vendor_code, product_code)
    end

    def self.find_active_proxies_for_context(context)
      find_all_proxies_for_context(context).where('lti_tool_proxies.workflow_state = ?', 'active')
    end

    def self.find_installed_proxies_for_context(context)
      find_all_proxies_for_context(context).where('lti_tool_proxies.workflow_state <> ?', 'deleted')
    end

    def self.find_all_proxies_for_context(context)
      account_ids = context.account_chain.map { |a| a.id }

      account_sql_string = account_ids.each_with_index.map { |x, i| "('Account',#{x},#{i})" }.unshift("('#{context.class.name}',#{context.id},#{0})").join(',')

      subquery = ToolProxyBinding.select('DISTINCT ON (lti_tool_proxies.id) lti_tool_proxy_bindings.*').joins(:tool_proxy).
        joins("INNER JOIN ( VALUES #{account_sql_string}) as x(context_type, context_id, ordering) ON lti_tool_proxy_bindings.context_type = x.context_type AND lti_tool_proxy_bindings.context_id = x.context_id").
        where('(lti_tool_proxy_bindings.context_type = ? AND lti_tool_proxy_bindings.context_id = ?) OR (lti_tool_proxy_bindings.context_type = ? AND lti_tool_proxy_bindings.context_id IN (?))', context.class.name, context.id, 'Account', account_ids).
        order('lti_tool_proxies.id, x.ordering').to_sql
      ToolProxy.joins("JOIN (#{subquery}) bindings on lti_tool_proxies.id = bindings.tool_proxy_id").where('bindings.enabled = true')
    end

    def self.capability_enabled_in_context?(context, capability)
      tool_proxies = ToolProxy.find_active_proxies_for_context(context)
      return true if tool_proxies.map(&:enabled_capabilities).flatten.include? capability
      capabilities = MessageHandler.where(tool_proxy_id: tool_proxies.map(&:id)).pluck(:capabilities).flatten
      capabilities.include? capability
    end

    def reregistration_message_handler
      return @reregistration_message_handler if @reregistration_message_handler
      if default_resource_handler
        @reregistration_message_handler ||= default_resource_handler.message_handlers.
            by_message_types(IMS::LTI::Models::Messages::ToolProxyUpdateRequest::MESSAGE_TYPE).first
      end
      @reregistration_message_handler
    end

    def default_resource_handler
      @default_resource_handler ||= resources.where(resource_type_code: 'instructure.com:default').first
    end

    def update?
      self.update_payload.present?
    end

    def ims_tool_proxy
      @_ims_tool_proxy ||= IMS::LTI::Models::ToolProxy.from_json(raw_data)
    end

    def security_profiles
      ims_tool_proxy.tool_profile.security_profiles
    end

    def enabled_capabilities
      ims_tool_proxy.enabled_capabilities
    end

    def matching_tool_profile?(other_profile)
      profile = raw_data['tool_profile']

      return false if profile.dig('product_instance', 'product_info', 'product_family', 'vendor', 'code') !=
        other_profile.dig('product_instance', 'product_info', 'product_family', 'vendor', 'code')

      return false if profile.dig('product_instance', 'product_info', 'product_family', 'code') !=
        other_profile.dig('product_instance', 'product_info', 'product_family', 'code')

      resource_handlers = profile['resource_handler']
      other_resource_handlers = other_profile['resource_handler']

      rh_names = resource_handlers.map { |rh| rh.dig('resource_type', 'code') }
      other_rh_names = other_resource_handlers.map { |rh| rh.dig('resource_type', 'code') }
      return false if rh_names.sort != other_rh_names.sort

      true
    end

    def resource_codes
      {
        product_code: product_family.product_code,
        vendor_code: product_family.vendor_code
      }
    end

    def configured_assignments
      message_handler = resources.preload(:message_handlers).map(&:message_handlers).flatten.find do |mh|
        mh.capabilities&.include?(Lti::ResourcePlacement::SIMILARITY_DETECTION_LTI2)
      end
      AssignmentConfigurationToolLookup.where(
        tool_product_code: product_family.product_code,
        tool_vendor_code: product_family.vendor_code,
        tool_resource_type_code: message_handler&.resource_handler&.resource_type_code
      ).preload(:assignment).map(&:assignment)
    end

    def find_service(service_id, action)
      ims_tool_proxy.tool_profile&.service_offered&.find do |s|
        s.id.include?(service_id) && s.action.include?(action)
      end
    end

    def matches?(vendor_code:, product_code:, resource_type_code:)
      return false if vendor_code != product_family.vendor_code
      return false if product_code != product_family.product_code
      return false if resources.where(resource_type_code: resource_type_code).empty?

      true
    end
  end
end
