#
# Copyright (C) 2011 Instructure, Inc.
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
module CC::Importer
  module WebcontentConverter
    include CC::Importer

    def create_file_map
      file_map = {}

      @manifest.css("resource[type=#{WEBCONTENT}][href^=#{WEB_RESOURCES_FOLDER}]").each do |res|
        file = {}
        file['migration_id'] = res['identifier']
        file['path_name'] = res['href'].sub(WEB_RESOURCES_FOLDER + '/', '')
        file['file_name'] = File.basename file['path_name']
        file['type'] = 'FILE_TYPE'

        file_map[file['migration_id']] = file
      end

      file_map
    end

    def package_course_files
      zip_file = File.join(@base_export_dir, 'all_files.zip')
      make_export_dir
      path = get_full_path(WEB_RESOURCES_FOLDER)
      Zip::ZipFile.open(zip_file, 'w') do |zipfile|
        Dir["#{path}/**/**"].each do |file|
          file_path = file.sub(path+'/', '')
          zipfile.add(file_path, file)
        end
      end

      File.expand_path(zip_file)
    end

  end
end
