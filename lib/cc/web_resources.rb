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
      hidden_locked_files = {:hidden_folders=>[], :locked_folders=>[], :hidden_files=>[], :locked_files=>[]}
      
      zipper = ContentZipper.new
      zipper.process_folder(course_folder, @zip_file, [CCHelper::WEB_RESOURCES_FOLDER]) do |file, folder_names|
        if file.is_a? Folder
          dir = File.join(folder_names[1..-1])
          hidden_locked_files[:hidden_folders] << dir if file.hidden? 
          hidden_locked_files[:locked_folders] << dir if file.locked 
          next
        end

        path = File.join(folder_names, file.display_name)
        migration_id = CCHelper.create_key(file)
        hidden_locked_files[:hidden_files] << migration_id if file.hidden?
        @resources.resource(
                "type" => CCHelper::WEBCONTENT,
                :identifier => migration_id,
                :href => path
        ) do |res|
          if file.locked
            hidden_locked_files[:locked_files] << migration_id
            res.metadata do |meta_node|
              meta_node.lom :lom do |lom_node|
                lom_node.lom :educational do |edu_node|
                  edu_node.lom :intendedEndUserRole do |role_node|
                    role_node.lom :source, "IMSGLC_CC_Rolesv1p1"
                    role_node.lom :value, "Instructor"
                  end
                end
              end
            end
          end
          res.file(:href=>path)
        end
      end
      
      add_meta_info_for_files(hidden_locked_files)
      
    end
    
    def files_meta_path
      File.join(CCHelper::COURSE_SETTINGS_DIR, CCHelper::FILES_META)
    end
    
    def add_meta_info_for_files(files)
      
      files_file = File.new(File.join(@canvas_resource_dir, CCHelper::FILES_META), 'w')
      rel_path = files_meta_path
      document = Builder::XmlMarkup.new(:target=>files_file, :indent=>2)
      
      document.instruct!
      document.fileMeta(
          "xmlns" => CCHelper::CANVAS_NAMESPACE,
          "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
          "xsi:schemaLocation"=> "#{CCHelper::CANVAS_NAMESPACE} #{CCHelper::XSD_URI}"
      ) do |root_node|
        if !files[:hidden_folders].empty?
          root_node.hidden_folders do |folders_node|
            files[:hidden_folders].each do |folder|
              folders_node.folder folder
            end
          end
        end
        if !files[:locked_folders].empty?
          root_node.locked_folders do |folders_node|
            files[:locked_folders].each do |folder|
              folders_node.folder folder
            end
          end
        end
        if !files[:hidden_files].empty?
          root_node.hidden_files do |folders_node|
            files[:hidden_files].each do |file|
              folders_node.attachment_identifierref file
            end
          end
        end
        if !files[:locked_files].empty?
          root_node.locked_files do |folders_node|
            files[:locked_files].each do |file|
              folders_node.attachment_identifierref file
            end
          end
        end
      end

      files_file.close if files_file
      rel_path
    end

    def add_media_objects
      return unless Kaltura::ClientV3.config
      client = Kaltura::ClientV3.new
      client.startSession(Kaltura::SessionType::ADMIN)

      @course.media_objects.active.find_all do |obj|
        migration_id = CCHelper.create_key(obj)
        info = CCHelper.media_object_info(obj, client)
        next unless info[:asset]
        url = client.flavorAssetGetDownloadUrl(info[:asset][:id])

        path = base_path = File.join(CCHelper::WEB_RESOURCES_FOLDER, 'media_objects', info[:filename])

        remote_stream = open(url)
        @zip_file.get_output_stream(path) do |stream|
          FileUtils.copy_stream(remote_stream, stream)
        end

        if url
          @resources.resource(
            "type" => CCHelper::WEBCONTENT,
            :identifier => migration_id,
            :href => path
          ) do |res|
            res.file(:href => path)
          end
        end
      end
    end
  end
end
