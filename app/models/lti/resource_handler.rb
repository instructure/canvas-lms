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
  class ResourceHandler < ActiveRecord::Base

    attr_readonly :created_at

    belongs_to :tool_proxy, class_name: 'Lti::ToolProxy'
    has_many :message_handlers, class_name: 'Lti::MessageHandler', :foreign_key => :resource_handler_id, dependent: :destroy
    has_many :placements, class_name: 'Lti::ResourcePlacement', through: :message_handlers

    serialize :icon_info

    validates :resource_type_code, :name, :tool_proxy, presence: true

    def find_message_by_type(message_type)
      message_handlers.by_message_types(message_type).first
    end

    def self.by_product_family(product_family, context)
      tool_proxies = ToolProxy.find_active_proxies_for_context(context)
      tool_proxies = tool_proxies.where(product_family: product_family)
      tool_proxies.map { |tp| tp.resources.to_a.flatten }.flatten
    end


    def self.by_resource_codes(vendor_code:, product_code:, resource_type_code:, context:)
      product_family = ProductFamily.find_by(vendor_code: vendor_code,
                                             product_code: product_code)
      possible_handlers = ResourceHandler.by_product_family(product_family, context)
      possible_handlers.select { |rh| rh.resource_type_code == resource_type_code}
    end

    def find_or_create_tool_setting(context: nil, resource_url: nil, link_fragment: nil)
      context ||= tool_proxy.context
      mh = message_handlers.find_by(message_type: MessageHandler::BASIC_LTI_LAUNCH_REQUEST)
      resource_link_id = mh.build_resource_link_id(context: context, link_fragment: link_fragment)

      tool_setting = Lti::ToolSetting.find_by(resource_link_id: resource_link_id)
      tool_setting ||= ToolSetting.new
      tool_setting.update_attributes(resource_link_id: resource_link_id,
                                     context: context,
                                     product_code: tool_proxy.product_family.product_code,
                                     vendor_code: tool_proxy.product_family.vendor_code,
                                     resource_type_code: resource_type_code,
                                     resource_url: resource_url)
      tool_setting
    end
  end
end
