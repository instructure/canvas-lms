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
require 'set'

module CC
  module WebResources
    def add_course_files
      return if for_course_copy

      course_folder = Folder.root_folders(@course).first
      files_with_metadata = { :folders => [], :files => [] }
      @added_attachment_ids = Set.new

      zipper = ContentZipper.new(:check_user => false)
      zipper.process_folder(course_folder, @zip_file, [CCHelper::WEB_RESOURCES_FOLDER]) do |file, folder_names|
        begin
          if file.is_a? Folder
            dir = File.join(folder_names[1..-1])
            files_with_metadata[:folders] << [file, dir] if file.hidden? || file.locked
            next
          end
          
          @added_attachment_ids << file.id
          path = File.join(folder_names, file.display_name)
          migration_id = CCHelper.create_key(file)
          if file.hidden? || file.locked
            files_with_metadata[:files] << [file, migration_id]
          end
          @resources.resource(
                  "type" => CCHelper::WEBCONTENT,
                  :identifier => migration_id,
                  :href => path
          ) do |res|
            if file.locked
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
        rescue
          title = file.unencoded_filename rescue I18n.t('course_exports.unknown_titles.file', "Unknown file")
          add_error(I18n.t('course_exports.errors.file', "The file \"%{file_name}\" failed to export", :file_name => title), $!)
        end
      end
      
      add_meta_info_for_files(files_with_metadata)
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
        if !files[:folders].empty?
          root_node.folders do |folders_node|
            files[:folders].each do |folder, path|
              folders_node.folder(:path => path) do |folder_node|
                folder_node.locked "true" if folder.locked
                folder_node.hidden "true" if folder.hidden?
              end
            end
          end
        end
        
        if !files[:files].empty?
          root_node.files do |files_node|
            files[:files].each do |file, migration_id|
              files_node.file(:identifier => migration_id) do |file_node|
                file_node.locked "true" if file.locked
                file_node.hidden "true" if file.hidden?
                file_node.display_name file.display_name if file.display_name != file.unencoded_filename
              end
            end
          end
        end
      end

      files_file.close if files_file
      rel_path
    end

    def add_media_objects(html_content_exporter)
      return if for_course_copy
      return unless Kaltura::ClientV3.config
      client = Kaltura::ClientV3.new
      client.startSession(Kaltura::SessionType::ADMIN)

      html_content_exporter.used_media_objects.each do |obj|
        next if @added_attachment_ids.include?(obj.attachment_id)
        begin
          migration_id = CCHelper.create_key(obj)
          info = html_content_exporter.media_object_infos[obj.id]
          next unless info && info[:asset]
          url = client.flavorAssetGetDownloadUrl(info[:asset][:id])

          path = base_path = File.join(CCHelper::WEB_RESOURCES_FOLDER, CCHelper::MEDIA_OBJECTS_FOLDER, info[:filename])

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
        rescue
          add_error(I18n.t('course_exports.errors.media_file', "A media file failed to export"), $!)
        end
      end
    end
  end
end
