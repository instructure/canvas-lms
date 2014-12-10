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

      @html_exporter.referenced_files.keys.each do |att_id|
        add_item_to_export("attachment_#{att_id}", "attachments")
      end

      course_folder = Folder.root_folders(@course).first
      files_with_metadata = { :folders => [], :files => [] }
      @added_attachment_ids = Set.new

      zipper = ContentZipper.new(:check_user => false)
      zipper.process_folder(course_folder, @zip_file, [CCHelper::WEB_RESOURCES_FOLDER], :exporter => @manifest.exporter) do |file, folder_names|
        begin
          if file.is_a? Folder
            dir = File.join(folder_names[1..-1])
            files_with_metadata[:folders] << [file, dir] if file.hidden? || file.locked
            next
          end

          @added_attachment_ids << file.id
          path = File.join(folder_names, file.display_name)
          migration_id = CCHelper.create_key(file)
          if file.hidden? || file.locked || file.usage_rights
            files_with_metadata[:files] << [file, migration_id]
          end
          @resources.resource(
                  "type" => CCHelper::WEBCONTENT,
                  :identifier => migration_id,
                  :href => path
          ) do |res|
            if file.locked || file.usage_rights
              res.metadata do |meta_node|
                meta_node.lom :lom do |lom_node|
                  if file.locked
                    lom_node.lom :educational do |edu_node|
                      edu_node.lom :intendedEndUserRole do |role_node|
                        role_node.lom :source, "IMSGLC_CC_Rolesv1p1"
                        role_node.lom :value, "Instructor"
                      end
                    end
                  end
                  if file.usage_rights
                    lom_node.lom :rights do |rights_node|
                      rights_node.lom :copyrightAndOtherRestrictions do |node|
                        node.lom :value, (file.usage_rights.license == 'public_domain') ? "no" : "yes"
                      end
                      description = []
                      description << file.usage_rights.legal_copyright if file.usage_rights.legal_copyright.present?
                      description << file.usage_rights.license_name unless file.usage_rights.license == 'private'
                      rights_node.lom :description do |desc|
                        desc.lom :string, description.join('\n')
                      end
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
                if file.usage_rights
                  file_node.usage_rights(:use_justification => file.usage_rights.use_justification) do |node|
                    node.legal_copyright file.usage_rights.legal_copyright if file.usage_rights.legal_copyright.present?
                    node.license file.usage_rights.license if file.usage_rights.license.present?
                  end
                end
              end
            end
          end
        end
      end

      files_file.close if files_file
      rel_path
    end

    def process_media_tracks(tracks, media_file_migration_id, media_obj, video_path)
      media_obj.media_tracks.each do |mt|
        track_id = CCHelper.create_key(mt.content)
        mt_path = video_path + ".#{mt.locale}.#{mt.kind}"
        @zip_file.get_output_stream(mt_path) do |stream|
          stream.write mt.content
        end
        @resources.resource(
            "type" => CCHelper::WEBCONTENT,
            :identifier => track_id,
            :href => mt_path
        ) do |res|
          res.file(:href => mt_path)
        end
        tracks[media_file_migration_id] ||= []
        tracks[media_file_migration_id] << {
            kind: mt.kind,
            locale: mt.locale,
            identifierref: track_id
        }
      end
    end

    def add_tracks(track_map)
      tracks_file = File.new(File.join(@canvas_resource_dir, CCHelper::MEDIA_TRACKS), 'w')
      document = Builder::XmlMarkup.new(:target=>tracks_file, :indent=>2)
      document.instruct!
      document.media_tracks(
          "xmlns" => CCHelper::CANVAS_NAMESPACE,
          "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
          "xsi:schemaLocation"=> "#{CCHelper::CANVAS_NAMESPACE} #{CCHelper::XSD_URI}"
      ) do |root_node|
        track_map.each do |file_id, track_list|
          # <media identifierref='(media file resource id)'>
          root_node.media(identifierref: file_id) do |media_node|
            track_list.each do |track|
              # <track identifierref='(srt resource id)' kind='subtitles' locale='en'/>
              media_node.track(track)
            end
          end
        end
      end
      tracks_file.close
    end

    MAX_MEDIA_OBJECT_SIZE = 4.gigabytes
    def add_media_objects(html_content_exporter)
      return if for_course_copy
      return unless CanvasKaltura::ClientV3.config

      # check to make sure we don't export more than 4 gigabytes of media objects
      total_size = 0
      html_content_exporter.used_media_objects.each do |obj|
        next if @added_attachment_ids.include?(obj.attachment_id)

        info = html_content_exporter.media_object_infos[obj.id]
        next unless info && info[:asset] && info[:asset][:size]

        total_size += info[:asset][:size].to_i.kilobytes
      end
      if total_size > MAX_MEDIA_OBJECT_SIZE
        add_error(I18n.t('course_exports.errors.media_files_too_large',
                         "Media files were not exported because the total file size was too large."))
        return
      end

      client = CanvasKaltura::ClientV3.new
      client.startSession(CanvasKaltura::SessionType::ADMIN)

      tracks = {}
      html_content_exporter.used_media_objects.each do |obj|
        next if @added_attachment_ids.include?(obj.attachment_id)
        begin
          migration_id = CCHelper.create_key(obj)
          info = html_content_exporter.media_object_infos[obj.id]
          next unless info && info[:asset]

          unless CanvasKaltura::ClientV3::ASSET_STATUSES[info[:asset][:status]] == :READY &&
            url = (client.flavorAssetGetPlaylistUrl(obj.media_id, info[:asset][:id]) || client.flavorAssetGetDownloadUrl(info[:asset][:id]))
            add_error(I18n.t('course_exports.errors.media_file', "A media file failed to export"))
            next
          end

          path = File.join(CCHelper::WEB_RESOURCES_FOLDER, CCHelper::MEDIA_OBJECTS_FOLDER, info[:filename])

          remote_stream = open(url)
          @zip_file.get_output_stream(path) do |stream|
            FileUtils.copy_stream(remote_stream, stream)
          end

          @resources.resource(
                  "type" => CCHelper::WEBCONTENT,
                  :identifier => migration_id,
                  :href => path
          ) do |res|
            res.file(:href => path)
          end

          process_media_tracks(tracks, migration_id, obj, path)
        rescue
          add_error(I18n.t('course_exports.errors.media_file', "A media file failed to export"), $!)
        end
      end

      add_tracks(tracks)
    end
  end
end
