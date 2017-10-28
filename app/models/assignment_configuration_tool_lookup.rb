#
# Copyright (C) 2016 - present Instructure, Inc.
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

class AssignmentConfigurationToolLookup < ActiveRecord::Base
  belongs_to :tool, polymorphic: [:context_external_tool, message_handler: 'Lti::MessageHandler']
  belongs_to :assignment
  after_create :create_subscription
  # Do not add before_destroy or after_destroy, these records are "delete_all"ed

  def lti_tool
    @_lti_tool ||= begin
      if tool_id.present?
        tool
      elsif tool_type == 'Lti::MessageHandler'
        Lti::MessageHandler.by_resource_codes(
          vendor_code: tool_vendor_code,
          product_code: tool_product_code,
          resource_type_code: tool_resource_type_code,
          context: assignment.course
        )
      end
    end
  end

  def destroy_subscription
    return unless lti_tool.instance_of? Lti::MessageHandler
    tool_proxy = lti_tool.resource_handler.tool_proxy
    Lti::AssignmentSubscriptionsHelper.new(tool_proxy).destroy_subscription(subscription_id)
  end

  def resource_codes
    if tool_type == 'Lti::MessageHandler' && tool_id.blank?
      return {
        product_code: tool_product_code,
        vendor_code: tool_vendor_code,
        resource_type_code: tool_resource_type_code
      }
    elsif tool_type == 'Lti::MessageHandler' && tool_id.present?
      return lti_tool.resource_codes
    end
    {}
  end

  def self.by_message_handler(message_handler, assignment)
    product_family = message_handler.resource_handler.tool_proxy.product_family
    AssignmentConfigurationToolLookup.where(
      assignment: assignment,
      tool_product_code: product_family.product_code,
      tool_vendor_code: product_family.vendor_code,
      tool_resource_type_code: message_handler.resource_handler.resource_type_code
    )
  end

  def self.by_tool_proxy(tool_proxy)
    message_handler = tool_proxy.resources.preload(:message_handlers).map(&:message_handlers).flatten.find do |mh|
      mh.capabilities&.include?(Lti::ResourcePlacement::SIMILARITY_DETECTION_LTI2)
    end
    where(
      tool_product_code: tool_proxy.product_family.product_code,
      tool_vendor_code: tool_proxy.product_family.vendor_code,
      tool_resource_type_code: message_handler&.resource_handler&.resource_type_code
    ).preload(:assignment).map(&:assignment)
  end

  private

  def create_subscription
    return unless lti_tool.instance_of? Lti::MessageHandler
    tool_proxy = lti_tool.resource_handler.tool_proxy
    subscription_helper = Lti::AssignmentSubscriptionsHelper.new(tool_proxy, assignment)
    self.update_attributes(subscription_id: subscription_helper.create_subscription)
  end
end
