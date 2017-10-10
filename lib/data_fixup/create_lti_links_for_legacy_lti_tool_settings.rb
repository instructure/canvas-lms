#
# Copyright (C) 2017 - present Instructure, Inc.
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

module DataFixup::CreateLtiLinksForLegacyLtiToolSettings

  def self.run
    Lti::ToolSetting.where.not(product_code: nil, vendor_code: nil, resource_type_code: nil, resource_link_id: nil).find_each do |tool_setting|
      Lti::Link.transaction do
        originality_report = OriginalityReport.find_by(link_id: tool_setting.resource_link_id)
        link = Lti::Link.create_with({
          product_code: tool_setting.product_code,
          vendor_code: tool_setting.vendor_code,
          resource_type_code: tool_setting.resource_type_code,
          custom_parameters: tool_setting.custom_parameters,
          resource_url: tool_setting.resource_url,
          linkable: originality_report
        }).find_or_create_by!(resource_link_id: tool_setting.resource_link_id)
      end
    end
  end

end
