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
    has_many :bindings, class_name: "Lti::ToolProxyBinding", dependent: :destroy
    has_many :resources, class_name: "Lti::ResourceHandler", dependent: :destroy
    has_many :tool_settings, class_name: "Lti::ToolSetting", dependent: :destroy
    has_many :message_handlers, class_name: "Lti::MessageHandler"

    belongs_to :context, polymorphic: [:course, :account]
    belongs_to :product_family, class_name: "Lti::ProductFamily"

    after_save :manage_subscription
    before_destroy :delete_subscription

    scope :active, -> { where(lti_tool_proxies: { workflow_state: "active" }) }

    serialize :raw_data
    serialize :update_payload

    validates :shared_secret, :guid, :product_version, :lti_version, :product_family_id, :workflow_state, :raw_data, :context, presence: true
    validates :guid, uniqueness: true
    validates :workflow_state, inclusion: { in: %w[active deleted disabled] }

    def active_in_context?(context)
      self.class.find_active_proxies_for_context(context).include?(self)
    end

    def self.find_active_proxies_for_context_by_vendor_code_and_product_code(context:, vendor_code:, product_code:)
      find_active_proxies_for_context(context)
        .eager_load(:product_family)
        .where("lti_product_families.vendor_code = ? AND lti_product_families.product_code = ?", vendor_code, product_code)
    end

    def self.find_active_proxies_for_context(context)
      find_all_proxies_for_context(context).where(lti_tool_proxies: { workflow_state: "active" })
    end

    def self.find_installed_proxies_for_context(context)
      find_all_proxies_for_context(context).where.not(lti_tool_proxies: { workflow_state: "deleted" })
    end

    def self.find_all_proxies_for_context(context)
      account_ids = context.account_chain.map(&:id)

      account_sql_string = account_ids.each_with_index.map { |x, i| "('Account',#{x},#{i})" }.unshift("('#{context.class.name}',#{context.id},0)").join(",")

      subquery = ToolProxyBinding.select("DISTINCT ON (lti_tool_proxies.id) lti_tool_proxy_bindings.*").joins(:tool_proxy)
                                 .joins("INNER JOIN ( VALUES #{account_sql_string}) as x(context_type, context_id, ordering) ON lti_tool_proxy_bindings.context_type = x.context_type AND lti_tool_proxy_bindings.context_id = x.context_id")
                                 .where("(lti_tool_proxy_bindings.context_type = ? AND lti_tool_proxy_bindings.context_id = ?) OR (lti_tool_proxy_bindings.context_type = ? AND lti_tool_proxy_bindings.context_id IN (?))", context.class.name, context.id, "Account", account_ids)
                                 .order("lti_tool_proxies.id, x.ordering").to_sql
      ToolProxy.joins("JOIN (#{subquery}) bindings on lti_tool_proxies.id = bindings.tool_proxy_id").where("bindings.enabled = true")
    end

    def self.proxies_in_order_by_codes(context:, vendor_code:, product_code:, resource_type_code:)
      account_ids = context.account_chain.map(&:id)

      # Added i+1 on this to ensure that the x.ordering later doesn't have 2 0's
      account_sql_string = account_ids.each_with_index.map { |x, i| "('Account',#{x},#{i + 1})" }.unshift("('#{context.class.name}',#{context.id},0)").join(",")

      subquery = ToolProxyBinding
                 .select("DISTINCT ON (x.ordering, lti_tool_proxy_bindings.tool_proxy_id) lti_tool_proxy_bindings.*, x.ordering")
                 .joins("INNER JOIN (
                           VALUES #{account_sql_string}) as x(context_type, context_id, ordering
                         ) ON lti_tool_proxy_bindings.context_type = x.context_type
                           AND lti_tool_proxy_bindings.context_id = x.context_id")
                 .where("(lti_tool_proxy_bindings.context_type = ? AND lti_tool_proxy_bindings.context_id = ?)
                         OR (lti_tool_proxy_bindings.context_type = ? AND lti_tool_proxy_bindings.context_id IN (?))",
                        context.class.name,
                        context.id,
                        "Account",
                        account_ids)
                 .order("lti_tool_proxy_bindings.tool_proxy_id, x.ordering").to_sql
      tools = joins("JOIN (#{subquery}) bindings on lti_tool_proxies.id = bindings.tool_proxy_id")
              .select("lti_tool_proxies.*, bindings.enabled AS binding_enabled")
              .joins(:product_family)
              .joins(:resources)
              # This is using a special ordering set up (to make sure we're going from the course to the
              # root account in order of parent accounts) and then takes the most recently installed tool
              .order("ordering, lti_tool_proxies.id DESC")
              .where(lti_tool_proxies: { workflow_state: "active" })
              .where("lti_product_families.vendor_code = ? AND lti_product_families.product_code = ?", vendor_code, product_code)
              .where(lti_resource_handlers: { resource_type_code: })
      # You can disable a tool_binding somewhere in the account chain, and anything below that that reenables it should be
      # available, but nothing above it, so we're getting rid of anything that is disabled and above
      tools.split { |tool| !tool.binding_enabled }.first
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
        @reregistration_message_handler ||= default_resource_handler.message_handlers
                                                                    .by_message_types(::IMS::LTI::Models::Messages::ToolProxyUpdateRequest::MESSAGE_TYPE).first
      end
      @reregistration_message_handler
    end

    def default_resource_handler
      @default_resource_handler ||= resources.where(resource_type_code: "instructure.com:default").first
    end

    def update?
      update_payload.present?
    end

    def ims_tool_proxy
      @_ims_tool_proxy ||= ::IMS::LTI::Models::ToolProxy.from_json(raw_data)
    end

    def security_profiles
      ims_tool_proxy.tool_profile.security_profiles
    end

    delegate :enabled_capabilities, to: :ims_tool_proxy

    def matching_tool_profile?(other_profile)
      profile = raw_data["tool_profile"]

      return false if profile.dig("product_instance", "product_info", "product_family", "vendor", "code") !=
                      other_profile.dig("product_instance", "product_info", "product_family", "vendor", "code")

      return false if profile.dig("product_instance", "product_info", "product_family", "code") !=
                      other_profile.dig("product_instance", "product_info", "product_family", "code")

      resource_handlers = profile["resource_handler"]
      other_resource_handlers = other_profile["resource_handler"]

      rh_names = resource_handlers.map { |rh| rh.dig("resource_type", "code") }
      other_rh_names = other_resource_handlers.map { |rh| rh.dig("resource_type", "code") }
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
      return false if resources.where(resource_type_code:).empty?

      true
    end

    def manage_subscription
      # Live Event subscriptions for plagiarism tools were too bulky to keep track
      # of when created from the individual assignments, so we are creating them on
      # the tool. We only want subscriptions for plagiarism tools, though. These
      # new subscriptions will get all events for the whole root account, and are
      # filtered by the associatedIntegrationId (tool guid) inside the live events
      # publish tool.
      if subscription_id.blank? && workflow_state == "active" && plagiarism_tool?
        subscription_id = Lti::PlagiarismSubscriptionsHelper.new(self)&.create_subscription
        update_columns(subscription_id:)
      elsif self.subscription_id.present? && workflow_state != "active"
        delete_subscription
      end
    end

    def delete_subscription
      return if subscription_id.nil?

      Lti::PlagiarismSubscriptionsHelper.new(self).destroy_subscription(subscription_id)
      update_columns(subscription_id: nil)
    end

    def plagiarism_tool?
      raw_data.try(:dig, "enabled_capability")&.include?(Lti::ResourcePlacement::SIMILARITY_DETECTION_LTI2)
    end

    def event_endpoint
      raw_data.try(:dig, "tool_profile", "service_offered")&.find do |service|
        service["@id"].include?("#vnd.Canvas.SubmissionEvent")
      end&.dig("endpoint")
    end
  end
end
