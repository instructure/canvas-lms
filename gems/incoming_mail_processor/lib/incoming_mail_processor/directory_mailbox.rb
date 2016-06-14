#
# Copyright (C) 2013 Instructure, Inc.
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

require 'fileutils'
require File.expand_path('../configurable_timeout', __FILE__)
require 'zlib'

module IncomingMailProcessor
  
  class DirectoryMailbox

    include ConfigurableTimeout

    attr_accessor :folder

    def initialize(options = {})
      @folder = options.fetch(:folder, "")
      @options = options
      wrap_with_timeout(self,
        [:folder_exists?, :files_in_folder, :read_file, :file?, :delete_file, :move_file, :create_folder])
    end

    def connect
      raise "Folder #{folder} does not exist." unless folder_exists?(folder)
    end

    def disconnect
      # nothing to do    
    end

    def each_message(opts={})
      filenames = files_in_folder(folder)
      filenames = filenames.select{|filename| Zlib.crc32(filename) % opts[:stride] == opts[:offset]} if opts[:stride] && opts[:offset]
      filenames.each do |filename|
        if file?(folder, filename)
          body = read_file(folder, filename)
          yield filename, body
        end
      end
    end

    def delete_message(filename)
      delete_file(folder, filename)
    end

    def move_message(filename, target_folder)
      unless folder_exists?(folder, target_folder)
        create_folder(folder, target_folder)
      end
      move_file(folder, filename, target_folder)
    end

    def unprocessed_message_count
      # not implemented, and used only for performance monitoring.
      nil
    end

  private
    def folder_exists?(folder, subfolder = nil)
      to_check = subfolder ? File.join(folder, subfolder) : folder
      File.directory?(to_check)
    end

    def files_in_folder(folder)
      Dir.entries(folder)
    end

    def read_file(folder, filename)
      File.read(File.join(folder, filename))
    end

    def file?(folder, filename)
      path = File.join(folder, filename)
      File.file?(path) || (@options[:read_pipes] && File.pipe?(path))
    end

    def delete_file(folder, filename)
      File.delete(File.join(folder, filename))
    end

    def move_file(folder, filename, target_folder)
      FileUtils.mv(File.join(folder, filename), File.join(folder, target_folder))
    end

    def create_folder(folder, subfolder)
      Dir.mkdir(File.join(folder, subfolder))
    end

  end

end