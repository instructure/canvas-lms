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
  class ToolProxy < ActiveRecord::Base

    has_many :bindings, class_name: 'Lti::ToolProxyBinding', dependent: :destroy
    has_many :resources, class_name: 'Lti::ResourceHandler', dependent: :destroy
    has_many :tool_settings, class_name: 'Lti::ToolSetting', dependent: :destroy
    has_many :message_handlers, class_name: 'Lti::MessageHandler'

    belongs_to :context, polymorphic: [:course, :account]
    belongs_to :product_family, class_name: 'Lti::ProductFamily'

    after_save :manage_subscription
    before_destroy :delete_subscription

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

    def self.proxies_in_order_by_codes(context:, vendor_code:, product_code:, resource_type_code:)
      account_ids = context.account_chain.map { |a| a.id }

      # Added i+1 on this to ensure that the x.ordering later doesn't have 2 0's
      account_sql_string = account_ids.each_with_index.map { |x, i| "('Account',#{x},#{i+1})" }.unshift("('#{context.class.name}',#{context.id},#{0})").join(',')

      subquery = ToolProxyBinding.
        select('DISTINCT ON (x.ordering, lti_tool_proxy_bindings.tool_proxy_id) lti_tool_proxy_bindings.*, x.ordering').
        joins("INNER JOIN (
            VALUES #{account_sql_string}) as x(context_type, context_id, ordering
          ) ON lti_tool_proxy_bindings.context_type = x.context_type
            AND lti_tool_proxy_bindings.context_id = x.context_id").
        where('(lti_tool_proxy_bindings.context_type = ? AND lti_tool_proxy_bindings.context_id = ?)
          OR (lti_tool_proxy_bindings.context_type = ? AND lti_tool_proxy_bindings.context_id IN (?))',
          context.class.name, context.id, 'Account', account_ids).
        order("lti_tool_proxy_bindings.tool_proxy_id, x.ordering").to_sql
      tools = self.joins("JOIN (#{subquery}) bindings on lti_tool_proxies.id = bindings.tool_proxy_id").
        select('lti_tool_proxies.*, bindings.enabled AS binding_enabled').
        # changed this from eager_load, because eager_load likes to wipe out custom select attributes
        joins(:product_family).
        joins(:resources).
        # changed the order to go from the special ordering set up (to make sure we're going from the course to the
        # root account in order of parent accounts) and then takes the most recently installed tool
        order('ordering, lti_tool_proxies.id DESC').
        where('lti_tool_proxies.workflow_state = ?', 'active').
        where('lti_product_families.vendor_code = ? AND lti_product_families.product_code = ?', vendor_code, product_code).
        where('lti_resource_handlers.resource_type_code = ?', resource_type_code)
      # You can disable a tool_binding somewhere in the account chain, and anything below that that reenables it should be
      # available, but nothing above it, so we're getting rid of anything that is disabled and above
      tools.split{|tool| !tool.binding_enabled}.first
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

    def manage_subscription
      # Live Event subscriptions for plagiarism tools were too bulky to keep track
      # of when created from the individual assignments, so we are creating them on
      # the tool. We only want subscriptions for plagiarism tools, though. These
      # new subscriptions will get all events for the whole root account, and are
      # filtered by the vendor code and product code inside the live events
      # publish tool.
      if subscription_id.blank? && workflow_state == 'active' && plagiarism_tool?
        self.update_columns(subscription_id: find_or_create_plagiarism_subscription)
      elsif subscription_id.present? && workflow_state != 'active'
        delete_subscription
      end
    end

    def plagiarism_tool?
      raw_data.try(:dig, 'enabled_capability')&.include?(Lti::ResourcePlacement::SIMILARITY_DETECTION_LTI2)
    end

    def event_endpoint
      raw_data.try(:dig, 'tool_profile', 'service_offered')&.find do |service|
        service['@id'].include?('#vnd.Canvas.SubmissionEvent')
      end&.dig('endpoint')
    end

    scope :with_event_endpoint, -> (endpoint) do
      where("raw_data like '%vnd.Canvas.SubmissionEvent%'").
        # This is not a good way to do this.  Yaml serialization can change, but right now it's all I've got.
        # We should put this into a real field.
        where("raw_data like '%endpoint: #{endpoint}%'")
    end

    def find_or_create_plagiarism_subscription
      # Tools with subscriptions and which match the current tool installation's product code, vendor code, and
      # SubmissionEvent endpoint
      tool_proxies = Lti::ToolProxy.active.joins(:product_family).
        with_event_endpoint(event_endpoint).
        where(lti_product_families: {product_code: product_family&.product_code, vendor_code: product_family&.vendor_code}).
        where.not(subscription_id: nil)
      # Search the accounts under the same root account to see if a subscription already exists
      # (we only need one subscription per root account)
      subscription_id = tool_proxies.joins(:account).
        # we should replace this with the tool_proxy root_account_id if/when we fill that
        find_by("coalesce(accounts.root_account_id, accounts.id) = ?", context&.resolved_root_account_id)&.subscription_id
      # Then search courses in case the tool was only directly installed on a course
      subscription_id ||= tool_proxies.joins(:course).
        find_by(courses: {root_account_id: self.context&.root_account_id})&.subscription_id
      # Then if we haven't found a subscription at all, we'll create a new one
      subscription_id || Lti::PlagiarismSubscriptionsHelper.new(self)&.create_subscription
    end

    def delete_subscription
      return if subscription_id.blank?
      old_subscription_id = subscription_id
      self.update_columns(subscription_id: nil)
      # We'll only delete the subscription from the live events publish tool if there
      # are no other tools using it
      return if Lti::ToolProxy.active.where(subscription_id: old_subscription_id).any?
      Lti::PlagiarismSubscriptionsHelper.new(self).destroy_subscription(old_subscription_id)
    end
  end
end
