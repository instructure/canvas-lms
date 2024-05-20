# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module Exporters
  class ZipExporter
    def self.create_zip_export(content_export, **)
      exporter = ZipExporter.new(content_export)
      exporter.export
    end

    def self.parse_selected_content(content_export)
      folders = []
      files = []
      context = content_export.context
      if content_export.selected_content.empty? || content_export.export_symbol?("all_attachments")
        folders = Folder.root_folders(context)
      else
        folders = (content_export.selected_content["folders"] || {})
                  .select { |_tag, included| Canvas::Plugin.value_to_boolean(included) }
                  .keys
                  .filter_map { |folder_tag| context.folders.active.find_by_asset_string(folder_tag, %w[Folder]) }
        files = (content_export.selected_content["attachments"] || {})
                .select { |_tag, included| Canvas::Plugin.value_to_boolean(included) }
                .keys
                .filter_map { |att_tag| context.attachments.not_deleted.find_by_asset_string(att_tag, %w[Attachment]) }
      end
      [folders, files]
    end

    def initialize(content_export)
      @export = content_export
      @user = @export.user
      @context = content_export.context
      @folders, @files = ZipExporter.parse_selected_content(content_export)

      @files_in_zip = Set.new
      compute_common_folder
      @export_dos_time = zip_dos_time
    end

    def archive_name
      @archive_name ||= "#{@common_folder_name.gsub(%r{[\x00-0x20/\\?:*"`\s]}, "_")}_export.zip"
    end

    def zip_dos_time
      time_zone = @export.settings[:user_time_zone]
      export_time =
        if time_zone.blank?
          Time.now.strftime("%Y-%m-%dT%H:%M:%S")
        else
          TZInfo::Timezone.get(time_zone).now.strftime("%Y-%m-%dT%H:%M:%S")
        end

      ::Zip::DOSTime.parse(export_time)
    end

    def export
      build_file_list
      Dir.mktmpdir do |dirname|
        zip_name = File.join(dirname, archive_name)
        Zip::OutputStream.open(zip_name) do |zipstream|
          @folder_list.each do |folder|
            add_folder(zipstream, folder)
          end
          @file_list.each do |file|
            add_file(zipstream, file)
          end
        end
        attach_zip(zip_name)
      end
    end

    private

    def compute_common_folder
      if (root_folder = @folders.detect { |f| f.parent_folder.nil? })
        # exporting all files
        @common_folder_name = root_folder.name
        @common_prefix = root_folder.full_name + "/"
      else
        # find the deepest folder all the provided files and folders share
        top_level_folder_elements = (@folders.map(&:parent_folder) + @files.map(&:folder)).uniq.map do |folder|
          folder.full_name.split("/")
        end
        common_elements = top_level_folder_elements.reduce do |a, b|
          n = (0...[a.length, b.length].min).detect { |ix| a[ix] != b[ix] }
          n ? a[0...n] : [a, b].min_by(&:length)
        end
        @common_folder_name = common_elements.last
        @common_prefix = common_elements.join("/") + "/"
      end
    end

    def build_file_list
      @file_list = []
      @folder_list = []
      @total_size = 0
      @total_copied = 0
      @folders.each { |folder| process_folder(folder) }
      @files.each { |file| process_file(file) }
    end

    def mock_session
      @user && { user_id: @user.id } # used for public_to_auth_users courses
    end

    def process_folder(folder)
      return unless folder.grants_right?(@user, mock_session, :read_contents)

      @folder_list << folder unless folder.root_folder?
      folder.sub_folders.active.each do |sub_folder|
        process_folder(sub_folder)
      end
      folder.file_attachments_visible_to(@user).each do |att|
        process_file(att)
      end
    end

    def process_file(att)
      if att.grants_right?(@user, mock_session, :download)
        @file_list << att
        @total_size += att.size || 0
      end
    end

    def create_zip_entry(zip_io, name)
      Zip::Entry.new(zip_io, name, nil, nil, nil, nil, nil, nil, @export_dos_time)
    end

    def add_file(zipstream, file)
      path = file.full_display_path
      path = path[@common_prefix.length..] if path.starts_with?(@common_prefix)
      wrote_header = false
      begin
        file.open do |chunk|
          unless wrote_header
            zip_entry = create_zip_entry(zipstream, path)
            zipstream.put_next_entry(zip_entry)
            wrote_header = true
          end
          zipstream.write(chunk)
          update_progress(chunk.size)
        end
      rescue => e
        @export.add_error(I18n.t("Skipped file %{filename} due to error", filename: file.display_name), e)
      end
    end

    def add_folder(zipstream, folder)
      path = folder.full_name
      path = path[@common_prefix.length..] if path.starts_with?(@common_prefix)
      zip_entry = create_zip_entry(zipstream, path + "/")
      zipstream.put_next_entry(zip_entry)
    end

    def attach_zip(zip_filename)
      attachment = @export.attachments.build
      attachment.uploaded_data = Canvas::UploadedFile.new(zip_filename, "application/zip")
      attachment.workflow_state = "zipped"
      attachment.file_state = "available"
      attachment.save!
      attachment
    end

    def update_progress(bytes_copied)
      return if @total_size == 0

      @last_percent ||= 0
      @last_update ||= 1.second.ago

      @total_copied += bytes_copied

      # clamp at 100% to prevent weirdness if Attachment#size lies
      # make database updates at most once per second
      percent_complete = [(@total_copied * 100) / @total_size, 100].min
      now = Time.now
      if (percent_complete - @last_percent >= 1) && (now - @last_update >= 1) # 1 second
        @export.fast_update_progress(percent_complete)
        @last_percent = percent_complete
        @last_update = now
      end
    end
  end
end
