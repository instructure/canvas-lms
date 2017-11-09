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
  module ToolProfileConverter
    include CC::Importer

    def convert_tool_profiles
      tool_profiles = []

      @manifest.css('resource[type=tool_profile]').each do |res|
        file = res.at_css('file')
        next unless file
        file_path = @package_root.item_path file['href']
        json = JSON.parse(File.read(file_path))
        json['resource_href'] = file['href']
        json['migration_id'] = res['identifier']
        tool_profiles << json
      end

      tool_profiles
    end
  end
end
