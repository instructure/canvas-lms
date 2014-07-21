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

require 'zip'
require 'fileutils'

class CanvasUnzip

  def self.unsafe_entry?(entry)
    return entry.symlink? || entry.name[0] == '/' || entry.name.split('/').include?('..')
  end

  def self.add_warning(warnings, entry, tag)
    warnings[tag] ||= []
    warnings[tag] << entry.name
  end

  # if a destination path is given, the archive will be extracted to that location
  #   * if a block is given, it will be called to ask whether an existing file should be overwritten
  #     yields |zip_entry, dest_path|; return true to overwrite
  #   * if no block is given, files will be skipped if they already exist
  # if no destination path is specified, then a block must be given
  #   * yields |zip_entry, index| for each (safe) zip entry
  # returns a hash of lists of entries that were skipped by reason
  #   { :unsafe => [list of entries],
  #     :already_exists => [list of entries],
  #     :unknown_compression_method => [list of entries] }
  def self.extract_archive(zip_filename, dest_path = nil, &block)
    warnings = {}
    Zip::File.open(zip_filename) do |zipfile|
      zipfile.entries.each_with_index do |entry, index|
        if unsafe_entry?(entry)
          add_warning(warnings, entry, :unsafe)
          next
        end
        if dest_path
          f_path = File.join(dest_path, entry.name)
          FileUtils.mkdir_p(File.dirname(f_path))
          begin
            entry.extract(f_path, &block)
          rescue Zip::DestinationFileExistsError
            add_warning(warnings, entry, :already_exists)
          rescue Zip::CompressionMethodError
            add_warning(warnings, entry, :unknown_compression_method)
          end
        else
          block.call(entry, index)
        end
      end
    end
    warnings
  end

end
