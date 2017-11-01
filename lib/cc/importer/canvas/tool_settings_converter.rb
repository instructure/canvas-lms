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
module CC::Importer::Canvas
  module ToolSettingsConverter
    include CC::Importer

    def convert_tool_settings
      tool_settings = []

      @manifest.css('resource[type=tool_setting]').each do |res|
        file = res.at_css('file')
        next unless file
        file_path = File.join @unzipped_file_path, file['href']
        json = JSON.parse(File.read(file_path))
        json['resource_href'] = file['href']
        json['migration_id'] = res['identifier']
        tool_settings << json
      end

      tool_settings
    end
  end
end
