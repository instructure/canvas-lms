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
module CC::Importer::Canvas
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

      convert_file_metadata(file_map)

      file_map
    end

    def convert_file_metadata(file_map)
      path = File.join(@unzipped_file_path, COURSE_SETTINGS_DIR, FILES_META)
      return unless File.exist? path
      doc = open_file_xml path

      if folders = doc.at_css('folders')
        @course[:hidden_folders] = []
        @course[:locked_folders] = []
        folders.css('folder').each do |folder|
          @course[:hidden_folders] << folder['path'] if get_bool_val(folder, 'hidden', false)
          @course[:locked_folders] << folder['path'] if get_bool_val(folder, 'locked', false)
        end
      end

      if files = doc.at_css('files')
        files.css('file').each do |file|
          id = file['identifier']
          if file_map[id]
            file_map[id][:hidden] = true if get_bool_val(file, 'hidden', false)
            file_map[id][:locked] = true if get_bool_val(file, 'locked', false)

            if unlock_at = get_time_val(file, 'unlock_at')
              file_map[id][:unlock_at] = unlock_at
            end
            if lock_at = get_time_val(file, 'lock_at')
              file_map[id][:lock_at] = lock_at
            end

            if display_name = file.at_css("display_name")
              file_map[id][:display_name] = display_name.text
            end
            if usage_rights = file.at_css("usage_rights")
              rights_hash = { :use_justification => usage_rights.attr('use_justification') }
              if legal_copyright = usage_rights.at_css('legal_copyright')
                rights_hash.merge!(:legal_copyright => legal_copyright.text)
              end
              if license = usage_rights.at_css('license')
                rights_hash.merge!(:license => license.text)
              end
              file_map[id][:usage_rights] = rights_hash
            end
          end
        end
      end
    end

    def package_course_files
      zip_file = File.join(@base_export_dir, 'all_files.zip')
      make_export_dir
      path = get_full_path(WEB_RESOURCES_FOLDER)
      Zip::File.open(zip_file, 'w') do |zipfile|
        Dir["#{path}/**/**"].each do |file|
          file_path = file.sub(path+'/', '')
          zipfile.add(file_path, file)
        end
      end

      File.expand_path(zip_file)
    end

  end
end
