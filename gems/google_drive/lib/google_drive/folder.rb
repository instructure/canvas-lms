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

module GoogleDrive
  class Folder
    attr_reader :name, :folders, :files

    def initialize(name, folders=[], files=[])
      @name = name
      @folders, @files = folders, files
    end

    def add_file(file)
      @files << file
    end

    def add_folder(folder)
      @folders << folder
    end

    def select(&block)
      Folder.new(@name,
                 @folders.map { |f| f.select(&block) }.select { |f| !f.files.empty? },
                 @files.select(&block))
    end

    def map(&block)
      @folders.map { |f| f.map(&block) }.flatten +
        @files.map(&block)
    end

    def flatten
      @folders.flatten + @files
    end

    def to_hash
      {
        :name => @name,
        :folders => @folders.map(&:to_hash),
        :files => @files.map(&:to_hash)
      }
    end
  end
end