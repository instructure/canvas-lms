# encoding: utf-8
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
#

module CC
  module ToolSettings
    def create_tool_settings
      Lti::ToolSetting.where(context: @course).each do |tool_setting|
        next if tool_setting.tool_proxy.blank?
        next unless export_object?(tool_setting, 'tool_settings')

        migration_id = create_key(tool_setting)

        file_name = "#{migration_id}.json"
        file_path = File.join(@export_dir, file_name)
        file = File.new(file_path, 'w')
        data = serialize_tool_setting(tool_setting)
        file.write(data.to_json)
        file.close

        @resources.resource(identifier: migration_id, type: 'tool_setting') do |res|
          res.file(href: file_name)
        end
      end
    end

    def serialize_tool_setting(tool_setting)
      {
        'tool_setting' => {
          'tool_proxy' => {
            'guid' => tool_setting.tool_proxy.guid,
            'product_code' => tool_setting.tool_proxy.product_family.product_code,
            'vendor_code' => tool_setting.tool_proxy.product_family.vendor_code
          },
          'custom' => tool_setting.custom,
          'custom_params' => tool_setting.custom_parameters
        }
      }
    end
  end
end
