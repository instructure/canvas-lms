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

module Canvas::Migration
  class Archive
    attr_reader :warnings

    def initialize(settings={})
      @settings = settings
      @warnings = []
    end

    def file
      @file ||= @settings[:archive_file] || download_archive
    end

    def zip_file
      unless defined?(@zip_file)
        @zip_file = Zip::File.open(file) rescue nil
      end
      @zip_file
    end

    def nested_dir
      return false unless zip_file
      unless defined?(@nested_dir)
        # sometimes people try to use packages that unzip to a folder containing the files we expect
        # so we should just try to handle it
        # see if there's only one directory at the root
        @nested_dir = nil
        base_entries = zip_file.glob("*")
        unless base_entries.any?{|e| !e.directory?}
          root_dirs = base_entries.reject{|e| File.basename(e.name) =~ UnzipAttachment::THINGS_TO_IGNORE_REGEX}
          @nested_dir = root_dirs.first.name if root_dirs.count == 1
        end
      end
      @nested_dir
    end

    def nest_entry_if_needed(entry)
      nested_dir ? File.join(nested_dir, entry) : entry
    end

    def read(entry)
      if zip_file
        zip_file.read(nest_entry_if_needed(entry))
      else
        unzip_archive
        path = package_root.item_path(entry)
        File.exist?(path) && File.read(path)
      end
    end

    def find_entry(entry)
      if zip_file
        zip_file.find_entry(nest_entry_if_needed(entry))
      else
        # if it's not an actual zip file
        # just extract the package (or try to) and look for the file
        unzip_archive
        File.exist?(package_root.item_path(entry))
      end
    end

    def download_archive
      config = ConfigFile.load('external_migration') || {}
      if @settings[:export_archive_path]
        File.open(@settings[:export_archive_path], 'rb')
      elsif @settings[:course_archive_download_url].present?
        _, uri = CanvasHttp.validate_url(@settings[:course_archive_download_url], check_host: true)
        CanvasHttp.get(@settings[:course_archive_download_url]) do |http_response|
          raise CanvasHttp::InvalidResponseCodeError.new(http_response.code.to_i) unless http_response.code.to_i == 200
          tmpfile = CanvasHttp.tempfile_for_uri(uri)
          http_response.read_body(tmpfile)
          tmpfile.rewind
          return tmpfile
        end
      elsif @settings[:attachment_id]
        att = Attachment.find(@settings[:attachment_id])
        att.open(:temp_folder => config[:data_folder], :need_local_file => true)
      else
        raise "No migration file found"
      end
    end

    def path
      file.path
    end

    def unzipped_file_path
      unless @unzipped_file_path
        config = ConfigFile.load('external_migration') || {}
        @unzipped_file_path = Dir.mktmpdir(nil, config[:data_folder].presence)
      end
      @unzipped_file_path
    end

    def package_root
      @package_root ||= PackageRoot.new(self.unzipped_file_path)
    end

    def get_converter
      Canvas::Migration::PackageIdentifier.new(self).get_converter
    end

    def unzip_archive
      return if @unzipped
      Rails.logger.debug "Extracting #{path} to #{unzipped_file_path}"

      warnings = CanvasUnzip.extract_archive(path, unzipped_file_path, nested_dir: nested_dir)
      @unzipped = true
      unless warnings.empty?
        diagnostic_text = ''
        warnings.each do |tag, files|
          diagnostic_text += tag.to_s + ': ' + files.join(', ') + "\n"
        end
        Rails.logger.debug "CanvasUnzip returned warnings: " + diagnostic_text
        add_warning(I18n.t('canvas.migration.warning.unzip_warning', 'The content package unzipped successfully, but with a warning'), diagnostic_text)
      end
      return true
    end

    def delete_unzipped_archive
      if @unzipped_file_path && File.directory?(@unzipped_file_path)
        FileUtils::rm_rf(@unzipped_file_path)
      end
    end

    # If the file is a zip file, unzip it, if it's an xml file, copy
    # it into the directory with the given file name
    def prepare_cartridge_file(file_name='imsmanifest.xml')
      if self.path.ends_with?('xml')
        FileUtils::cp(self.path, package_root.item_path(file_name))
      else
        unzip_archive
      end
    end

    def delete_unzipped_file
      if File.exist?(self.unzipped_file_path)
        FileUtils::rm_rf(self.unzipped_file_path)
      end
    end

    def add_warning(warning)
      @warnings << warning
    end
  end
end
