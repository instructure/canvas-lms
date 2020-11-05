# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module CC::Exporter::Epub
  class FilesDirectory
    def initialize(exporter)
      @files = exporter.unsupported_files
      @filename_prefix = exporter.filename_prefix
    end
    attr_reader :files

    def add_files
      files.each do |file_data|
        next unless file_data[:exists]
        File.open(file_data[:path_to_file]) do |file|
          file_path = file_data[:local_path]
          zip_file.add(file_path, file) { add_clone(file_path, file) }
        end
      end
    end

    def add_clone(file_path, file, count=0)
      count += 1
      clone_name = "#{file_path} (#{count})"
      zip_file.add(clone_name, file) { add_clone(file_path, file, count) }
    end

    def create
      return nil unless files.any?

      begin
        add_files
      ensure
        zip_file.close if zip_file
      end

      zip_file.to_s
    end

    def export_directory
      unless @_export_directory
        path = File.join(Dir.tmpdir, Time.zone.now.strftime("%s"))
        @_export_directory = FileUtils.mkdir_p(path)
      end

      @_export_directory.first
    end

    def filename
      "#{@filename_prefix}.zip"
    end

    def zip_file
      @_zip_file ||= Zip::File.new(
        File.join(export_directory, filename),
        Zip::File::CREATE
      )
    end
  end
end
