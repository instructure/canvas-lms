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
require 'canvas_mimetype_fu'
require 'rubygems/package'
require 'zlib'

class CanvasUnzip

  class CanvasUnzipError < ::StandardError; end
  class UnknownArchiveType < CanvasUnzipError; end
  class FileLimitExceeded < CanvasUnzipError; end
  class SizeLimitExceeded < CanvasUnzipError; end
  class DestinationFileExists < CanvasUnzipError; end

  Limits = Struct.new(:maximum_bytes, :maximum_files)

  def self.unsafe_entry?(entry)
    entry.symlink? || entry.name == '/' || entry.name.split('/').include?('..')
  end

  def self.add_warning(warnings, entry, tag)
    warnings[tag] ||= []
    warnings[tag] << entry.name
  end

  BUFFER_SIZE = 65536
  DEFAULT_BYTE_LIMIT = 50 << 30
  def self.default_limits(file_size)
    # * maximum byte count is, unless specified otherwise,
    #   100x the size of the uploaded zip, or a hard cap at 50GB
    # * default maximum file count is 100,000
    Limits.new([file_size * 100, DEFAULT_BYTE_LIMIT].min, 100_000)
  end

  # if a destination path is given, the archive will be extracted to that location
  #   * files will be skipped if they already exist
  # if no destination path is given, a block must be given,
  #   * yields |entry, index| for each (safe) zip/tar entry available to be extracted
  # returns a hash of lists of entries that were skipped by reason
  #   { :unsafe => [list of entries],
  #     :already_exists => [list of entries],
  #     :unknown_compression_method => [list of entries] }

  def self.extract_archive(archive_filename, dest_folder = nil, limits = nil, &block)
    warnings = {}
    limits ||= default_limits(File.size(archive_filename))
    bytes_left = limits.maximum_bytes
    files_left = limits.maximum_files

    raise ArgumentError, "File not found" unless File.exists?(archive_filename)
    raise ArgumentError, "Needs block or destination path" unless dest_folder || block

    each_entry(archive_filename) do |entry, index|
      if unsafe_entry?(entry)
        add_warning(warnings, entry, :unsafe)
        next
      end

      if block
        block.call(entry, index)
      else
        raise FileLimitExceeded if files_left <= 0
        begin
          f_path = File.join(dest_folder, entry.name)
          entry.extract(f_path, false, bytes_left) do |size|
            bytes_left -= size
            raise SizeLimitExceeded if bytes_left < 0
          end

          files_left -= 1
        rescue DestinationFileExists
          add_warning(warnings, entry, :already_exists)
        rescue Zip::CompressionMethodError
          add_warning(warnings, entry, :unknown_compression_method)
        end
      end
    end
    warnings
  end

  def self.each_entry(archive_filename)
    raise ArgumentError, "no block given" unless block_given?

    file = File.open(archive_filename)
    mime_type = File.mime_type?(file)
    if mime_type == 'application/x-gzip'
      file = Zlib::GzipReader.new(file)
      mime_type = 'application/x-tar' # it may not actually be a tar though, so rescue if there's a problem
    end

    if mime_type == 'application/zip'
      Zip::File.open(file) do |zipfile|
        zipfile.entries.each_with_index do |zip_entry, index|
          yield(Entry.new(zip_entry), index)
        end
      end
    elsif mime_type == 'application/x-tar'
      index = 0
      begin
        Gem::Package::TarReader.new(file).each do |tar_entry|
          next if tar_entry.header.typeflag == 'x'
          yield(Entry.new(tar_entry), index)
          index += 1
        end
      rescue Gem::Package::TarInvalidError
        raise UnknownArchiveType
      end
    else
      raise UnknownArchiveType
    end
  end

  class Entry
    attr_reader :entry, :type

    def initialize(entry)
      if entry.is_a?(Zip::Entry)
        @type = :zip
      elsif entry.is_a?(Gem::Package::TarReader::Entry)
        @type = :tar
      end

      raise CanvasUnzipError, "Invalid entry type" unless @type
      @entry = entry
    end

    def symlink?
      if type == :zip
        entry.symlink?
      elsif type == :tar
        entry.header.typeflag == "2"
      end
    end

    def directory?
      entry.directory?
    end

    def file?
      entry.file?
    end

    def name
      if type == :zip
        entry.name
      elsif type == :tar
        entry.full_name.sub(/^\.\//, '')
      end
    end

    def size
      if type == :zip
        entry.size
      elsif type == :tar
        entry.header.size
      end
    end

    # yields byte count
    def extract(dest_path, overwrite=false, maximum_size=DEFAULT_BYTE_LIMIT)
      dir = self.directory? ? dest_path : File.dirname(dest_path)
      FileUtils.mkdir_p(dir) unless File.exist?(dir)
      return unless self.file?

      raise SizeLimitExceeded if size > maximum_size
      if File.exist?(dest_path) && !overwrite
        raise DestinationFileExists, "Destination '#{dest_path}' already exists"
      end

      ::File.open(dest_path, "wb") do |os|
        if type == :zip
          entry.get_input_stream do |is|
            entry.set_extra_attributes_on_path(dest_path)
            buf = ''
            while buf = is.sysread(::Zip::Decompressor::CHUNK_SIZE, buf)
              os << buf
              yield(buf.size) if block_given?
            end
          end
        elsif type == :tar
          while buf = entry.read(BUFFER_SIZE)
            os << buf
            yield(buf.size) if block_given?
          end
        end
      end
    end
  end
end
