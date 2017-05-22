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

    validates_presence_of :resource_type_code, :name, :tool_proxy, :lookup_id
    before_validation :set_lookup_id

    def self.generate_lookup_id_for(resource_handler)
      tool_proxy = resource_handler.tool_proxy
      product_family = tool_proxy.product_family
      components = [product_family.product_code,
                    product_family.vendor_code,
                    resource_handler.resource_type_code].join('-')
      "#{components}-#{Canvas::Security.hmac_sha1(components)}"
    end

    private

    def set_lookup_id
      self.lookup_id ||= self.class.generate_lookup_id_for(self)
    end
  end
end
