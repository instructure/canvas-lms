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
module CC
  module WebResources
    def add_course_files
      course_folder = Folder.root_folders(@course).first
      
      zipper = ContentZipper.new
      zipper.process_folder(course_folder, @zip_file, [CCHelper::WEB_RESOURCES_FOLDER]) do |attachment, folder_names|
        path = File.join(folder_names, attachment.display_name)
        migration_id = CCHelper.create_key(attachment)
        @resources.resource(
                "type" => CCHelper::WEBCONTENT,
                :identifier => migration_id,
                :href => path
        ) do |res|
          res.file(:href=>path)
        end
      end
    end
  end
end