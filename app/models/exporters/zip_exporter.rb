#
# Copyright (C) 2014 Instructure, Inc.
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
    def self.create_zip_export(content_export, opts={})
      exporter = ZipExporter.new(content_export)
      exporter.export
    end

    def self.parse_selected_content(content_export)
      folders = []
      files = []
      context = content_export.context
      if content_export.selected_content.empty? || content_export.export_symbol?('all_attachments')
        folders = Folder.root_folders(context)
      else
        folders = (content_export.selected_content['folders'] || {}).select { |tag, included| Canvas::Plugin::value_to_boolean(included) }.keys.map do |folder_tag|
          context.folders.active.find_by_asset_string(folder_tag, %w(Folder))
        end.compact
        files = (content_export.selected_content['attachments'] || {}).select { |tag, included| Canvas::Plugin::value_to_boolean(included) }.keys.map do |att_tag|
          context.attachments.not_deleted.find_by_asset_string(att_tag, %w(Attachment))
        end.compact
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
    end

    def archive_name
      @archive_name ||= "#{@common_folder_name.gsub(/[\x00-0x20\/\\\?:*"`\s]/, '_')}_export.zip"
    end

    def export
      build_file_list
      Dir.mktmpdir do |dirname|
        zip_name = File.join(dirname, archive_name)
        Zip::OutputStream.open(zip_name) do |zipstream|
          @file_list.each do |file|
            add_file(zipstream, file)
          end
        end
        attach_zip(zip_name)
      end
    end

    private

    def compute_common_folder
      if root_folder = @folders.detect { |f| f.parent_folder.nil? }
        # exporting all files
        @common_folder_name = root_folder.name
        @common_prefix = root_folder.full_name + '/'
      else
        # find the deepest folder all the provided files and folders share
        top_level_folder_elements = (@folders.map(&:parent_folder) + @files.map(&:folder)).uniq.map do |folder|
          folder.full_name.split('/')
        end
        common_elements = top_level_folder_elements.reduce do |a, b|
          n = (0...[a.length, b.length].min).detect { |ix| a[ix] != b[ix] }
          n ? a[0...n] : [a, b].min_by(&:length)
        end
        @common_folder_name = common_elements.last
        @common_prefix = common_elements.join('/') + '/'
      end
    end

    def build_file_list
      @file_list = []
      @total_size = 0
      @total_copied = 0
      @folders.each { |folder| process_folder(folder) }
      @files.each { |file| process_file(file) }
    end

    def process_folder(folder)
      return unless folder.grants_right?(@user, :read_contents)
      folder.sub_folders.active.each do |sub_folder|
        process_folder(sub_folder)
      end
      folder.attachments.not_deleted.each do |att|
        process_file(att)
      end
    end

    def process_file(att)
      if att.grants_right?(@user, :download)
        @file_list << att
        @total_size += (att.size || 0)
      end
    end

    def add_file(zipstream, file)
      path = file.full_display_path
      path = path[@common_prefix.length..-1] if path.starts_with?(@common_prefix)
      zipstream.put_next_entry(path)
      file.open do |chunk|
        zipstream.write(chunk)
        update_progress(chunk.size)
      end
    end

    def attach_zip(zip_filename)
      attachment = @export.attachments.build
      attachment.uploaded_data = Rack::Test::UploadedFile.new(zip_filename, 'application/zip')
      attachment.workflow_state = 'zipped'
      attachment.file_state = 'available'
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
      if (percent_complete - @last_percent >= 1) && (now - @last_update >= 1.second)
        @export.fast_update_progress(percent_complete)
        @last_percent = percent_complete
        @last_update = now
      end
    end
  end
end