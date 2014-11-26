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
module CC::Importer::Standard
  module WebcontentConverter
    include CC::Importer

    def create_file_map
      resources_by_type(WEBCONTENT, "associatedcontent").each do |res|
        main_file = {}
        main_file[:migration_id] = res[:migration_id]
        main_file[:path_name] = res[:href]
        if res[:intended_user_role] == 'Instructor'
          main_file[:locked] = true
        end

        # add any extra files in this resource
        res[:files].each do |file_ref|
          next unless file_ref[:href]
          if !main_file[:path_name]
            # if the resource didn't have an href use the first file
            main_file[:path_name] = file_ref[:href]
            next
          elsif main_file[:path_name] == file_ref[:href]
            next
          end
          sub_file = {}
          sub_file[:path_name] = file_ref[:href]
          sub_file[:migration_id] = Digest::MD5.hexdigest(sub_file[:path_name])
          sub_file[:file_name] = File.basename sub_file[:path_name]
          sub_file[:type] = 'FILE_TYPE'
          add_course_file(sub_file)
        end

        if main_file[:path_name].present?
          main_file[:file_name] = File.basename main_file[:path_name]
          main_file[:type] = 'FILE_TYPE'
          add_course_file(main_file, true)
        end
      end
    end

    def package_course_files(file_map)
      zip_file = File.join(@base_export_dir, 'all_files.zip')
      make_export_dir

      Zip::File.open(zip_file, 'w') do |zipfile|
        file_map.each_value do |val|
          next if zipfile.entries.include?(val[:path_name])

          file_path = File.join(@unzipped_file_path, val[:path_name])
          if File.exists?(file_path)
            zipfile.add(val[:path_name], file_path) if !File.directory?(file_path)
          else
            web_file_path = File.join(@unzipped_file_path, WEB_RESOURCES_FOLDER, val[:path_name])
            if File.exists?(web_file_path)
              zipfile.add(val[:path_name], web_file_path) if !File.directory?(web_file_path)
            else
              val[:errored] = true
            end
          end
        end
      end

      File.expand_path(zip_file)
    end

  end
end
