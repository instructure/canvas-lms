# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
    def file_or_folder_restricted?(obj)
      obj.hidden? || obj.locked || obj.unlock_at || obj.lock_at
    end

    def content_zipper
      @zipper ||= ContentZipper.new
      @zipper.user = @user
      @zipper
    end

    def add_course_files
      return if for_course_copy

      (@html_exporter.referenced_files.keys + @html_exporter.referenced_assessment_question_files.keys).each do |att_id|
        add_item_to_export("attachment_#{att_id}", "attachments")
      end

      @html_exporter.referenced_assessment_question_files.each_value do |att|
        path = "#{CCHelper::WEB_RESOURCES_FOLDER}/assessment_questions#{att.full_display_path}"
        add_file_to_manifest(att, path, create_key(att))
        content_zipper.add_attachment_to_zip(att, @zip_file, path)
      end

      course_folder = Folder.root_folders(@course).first
      files_with_metadata = { folders: [], files: [] }
      if @html_exporter.referenced_assessment_question_files.present?
        aq_folder = Folder.new(name: "assessment_questions", full_name: "assessment_questions", hidden: true)
        files_with_metadata[:folders] << [aq_folder, "assessment_questions"]
      end
      @added_attachments = {}

      content_zipper.process_folder(
        course_folder,
        @zip_file,
        [CCHelper::WEB_RESOURCES_FOLDER],
        exporter: @manifest.exporter,
        referenced_files: @html_exporter.referenced_files
      ) do |file, folder_names|
        next if file.display_name.blank?

        if file.is_a? Folder
          dir = File.join(folder_names[1..])
          files_with_metadata[:folders] << [file, dir] if file_or_folder_restricted?(file) && export_symbol?(nil) # hacky way of checking selective exports
          next
        end

        path = File.join(folder_names, file.display_name)
        @added_attachments[file.id] = path
        migration_id = create_key(file)
        if file_or_folder_restricted?(file) || file.usage_rights || file.display_name != file.unencoded_filename || file.category == Attachment::ICON_MAKER_ICONS
          files_with_metadata[:files] << [file, migration_id]
        end
        add_file_to_manifest(file, path, migration_id)
      rescue
        title = file.unencoded_filename rescue I18n.t("course_exports.unknown_titles.file", "Unknown file")
        add_error(I18n.t("course_exports.errors.file", "The file \"%{file_name}\" failed to export", file_name: title), $!)
      end

      add_meta_info_for_files(files_with_metadata)
    end

    def add_file_to_manifest(file, path, migration_id)
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
                    node.lom :value, (file.usage_rights.license == "public_domain") ? "no" : "yes"
                  end
                  description = []
                  description << file.usage_rights.legal_copyright if file.usage_rights.legal_copyright.present?
                  description << file.usage_rights.license_name unless file.usage_rights.license == "private"
                  rights_node.lom :description do |desc|
                    desc.lom :string, description.join('\n')
                  end
                end
              end
            end
          end
        end
        res.file(href: path)
      end
    end

    def files_meta_path
      File.join(CCHelper::COURSE_SETTINGS_DIR, CCHelper::FILES_META)
    end

    def add_meta_info_for_files(files)
      files_file = File.new(File.join(@canvas_resource_dir, CCHelper::FILES_META), "w")
      rel_path = files_meta_path
      document = Builder::XmlMarkup.new(target: files_file, indent: 2)

      document.instruct!
      document.fileMeta(
        "xmlns" => CCHelper::CANVAS_NAMESPACE,
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        "xsi:schemaLocation" => "#{CCHelper::CANVAS_NAMESPACE} #{CCHelper::XSD_URI}"
      ) do |root_node|
        unless files[:folders].empty?
          root_node.folders do |folders_node|
            files[:folders].each do |folder, path|
              folders_node.folder(path:) do |folder_node|
                folder_node.locked "true" if folder.locked
                folder_node.hidden "true" if folder.hidden?
                folder_node.lock_at CCHelper.ims_datetime(folder.lock_at) if folder.lock_at
                folder_node.unlock_at CCHelper.ims_datetime(folder.unlock_at) if folder.unlock_at
              end
            end
          end
        end

        unless files[:files].empty?
          root_node.files do |files_node|
            files[:files].each do |file, migration_id|
              files_node.file(identifier: migration_id) do |file_node|
                file_node.locked "true" if file.locked
                file_node.hidden "true" if file.hidden?
                file_node.lock_at CCHelper.ims_datetime(file.lock_at) if file.lock_at
                file_node.unlock_at CCHelper.ims_datetime(file.unlock_at) if file.unlock_at
                file_node.display_name file.display_name if file.display_name != file.unencoded_filename
                file_node.category file.category
                if file.usage_rights
                  file_node.usage_rights(use_justification: file.usage_rights.use_justification) do |node|
                    node.legal_copyright file.usage_rights.legal_copyright if file.usage_rights.legal_copyright.present?
                    node.license file.usage_rights.license if file.usage_rights.license.present?
                  end
                end
              end
            end
          end
        end
      end

      files_file&.close
      rel_path
    end

    def attachments_for_export(folder)
      opts = { exporter: @manifest.exporter, referenced_files: @html_exporter.referenced_files, ignore_updated_at: true }
      attachments_for_export = []
      attachments_for_export += content_zipper.folder_attachments_for_export(folder, opts)
      folder.active_sub_folders.each do |sub_folder|
        attachments_for_export += attachments_for_export(sub_folder)
      end
      attachments_for_export
    end

    def process_media_tracks
      attachments = attachments_for_export(Folder.root_folders(@course).first)
      attachments += Attachment.where(context: @course, media_entry_id: @html_exporter.used_media_objects.map(&:media_id))
      attachments += Attachment.where(context: @course, id: @html_exporter.referenced_files.keys).where.not(media_entry_id: nil)

      att_map = attachments.index_by(&:id)
      Attachment.media_tracks_include_originals(attachments).each_with_object({}) do |mt, tracks|
        file = att_map[mt.for_att_id]
        migration_id = create_key(file)
        tracks[migration_id] ||= []
        tracks[migration_id] << {
          kind: mt.kind,
          locale: mt.locale,
          identifierref: create_key(mt.content),
          content: mt.content
        }
        add_exported_asset(mt)
      end
    end

    def process_media_tracks_without_feature_flag(tracks, media_file_migration_id, media_obj, video_path)
      media_obj.media_tracks.each do |mt|
        track_id = create_key(mt.content)
        mt_path = video_path + ".#{mt.locale}.#{mt.kind}"
        @zip_file.get_output_stream(mt_path) do |stream|
          stream.write mt.content
        end
        @resources.resource(
          "type" => CCHelper::WEBCONTENT,
          :identifier => track_id,
          :href => mt_path
        ) do |res|
          res.file(href: mt_path)
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
      tracks_file = File.new(File.join(@canvas_resource_dir, CCHelper::MEDIA_TRACKS), "w")
      document = Builder::XmlMarkup.new(target: tracks_file, indent: 2)
      document.instruct!
      document.media_tracks(
        "xmlns" => CCHelper::CANVAS_NAMESPACE,
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        "xsi:schemaLocation" => "#{CCHelper::CANVAS_NAMESPACE} #{CCHelper::XSD_URI}"
      ) do |root_node|
        track_map.each do |file_id, track_list|
          # <media identifierref='(media file resource id)'>
          root_node.media(identifierref: file_id) do |media_node|
            track_list.each do |track|
              # <track identifierref='(srt resource id)' kind='subtitles' locale='en'/>
              media_node_creation(media_node, track)
            end
          end
        end
      end
      tracks_file.close
    end

    def media_node_creation(media_node, track)
      if Account.site_admin.feature_enabled?(:media_links_use_attachment_id)
        media_node.track(track[:content], track.slice(:kind, :locale, :identifierref))
      else
        media_node.track(track)
      end
    end

    def add_media_tracks
      track_map = process_media_tracks
      add_tracks(track_map)
    end

    def export_media_objects?
      CanvasKaltura::ClientV3.config && !for_course_copy
    end

    def media_object_path(path)
      File.join(CCHelper::WEB_RESOURCES_FOLDER, path)
    end

    MAX_MEDIA_OBJECT_SIZE = 4.gigabytes
    def add_media_objects(html_content_exporter = @html_exporter)
      return unless export_media_objects?

      # check to make sure we don't export more than 4 gigabytes of media objects
      total_size = 0
      html_content_exporter.used_media_objects.each do |obj|
        next if @added_attachments&.key?(obj.attachment_id)

        info = html_content_exporter.media_object_infos[obj.id]
        next unless info && info[:asset] && info[:asset][:size]

        total_size += info[:asset][:size].to_i.kilobytes
      end
      if total_size > MAX_MEDIA_OBJECT_SIZE
        add_error(I18n.t("course_exports.errors.media_files_too_large",
                         "Media files were not exported because the total file size was too large."))
        return
      end

      client = CC::CCHelper.kaltura_admin_session
      tracks = {}
      html_content_exporter.used_media_objects.each do |obj|
        migration_id = create_key(obj.attachment)
        info = html_content_exporter.media_object_infos[obj.id]
        next unless info && info[:asset]

        path = media_object_path(info[:path])

        # download from kaltura if the file wasn't already exported here in add_course_files
        if !@added_attachments || @added_attachments[obj.attachment_id] != path
          unless CanvasKaltura::ClientV3::ASSET_STATUSES[info[:asset][:status]] == :READY &&
                 (url = client.flavorAssetGetPlaylistUrl(obj.media_id, info[:asset][:id]) || client.flavorAssetGetDownloadUrl(info[:asset][:id]))
            add_error(I18n.t("course_exports.errors.media_file", "A media file failed to export"))
            next
          end

          CanvasHttp.get(url) do |http_response|
            raise CanvasHttp::InvalidResponseCodeError, http_response.code.to_i unless http_response.code.to_i == 200

            @zip_file.get_output_stream(path) do |stream|
              http_response.read_body(stream)
            end
          end

          @resources.resource(
            "type" => CCHelper::WEBCONTENT,
            :identifier => migration_id,
            :href => path
          ) do |res|
            res.file(href: path)
          end
        end

        unless Account.site_admin.feature_enabled?(:media_links_use_attachment_id)
          process_media_tracks_without_feature_flag(tracks, migration_id, obj, path)
        end
      rescue
        add_error(I18n.t("course_exports.errors.media_file", "A media file failed to export"), $!)
      end
      add_tracks(tracks) if @canvas_resource_dir && !Account.site_admin.feature_enabled?(:media_links_use_attachment_id)
    end
  end
end
