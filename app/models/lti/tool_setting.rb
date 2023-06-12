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

module Lti
  class ToolSetting < ActiveRecord::Base
    belongs_to :tool_proxy
    belongs_to :context, polymorphic: %i[course account attachment_association]

    validates :context, presence: { if: :has_resource_link_id? }

    serialize :custom
    serialize :custom_parameters

    class << self
      def custom_settings(tool_proxy_id, context, resource_link_id)
        tool_settings = ToolSetting.where("tool_proxy_id = ? and ((context_type = ? and context_id =?) OR context_id IS NULL) and (resource_link_id = ? OR resource_link_id IS NULL)",
                                          tool_proxy_id,
                                          context.class.to_s,
                                          context.id,
                                          resource_link_id)
                                   .order("context_id NULLS FIRST, resource_link_id NULLS FIRST").pluck(:custom).compact
        (tool_settings.present? && tool_settings.inject { |custom, h| custom.merge(h) }) || {}
      end
    end

    def message_handler(mh_context)
      MessageHandler.by_resource_codes(vendor_code:,
                                       product_code:,
                                       resource_type_code:,
                                       context: mh_context)
    end

    private

    def has_resource_link_id?
      resource_link_id.present?
    end
  end
end
