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
  module Exportable
    def content_cartridge
      self.attachment
    end

    def convert_to_epub
      exporter = CC::Exporter::Epub::Exporter.new(content_cartridge.open, sort_by_content_type?)
      epub = CC::Exporter::Epub::Book.new(exporter)
      files_directory = CC::Exporter::Epub::FilesDirectory.new(exporter)
      result = [ epub.create, files_directory.create ].compact
      exporter.cleanup_files
      result
    end

    def sort_by_content_type?
      false
    end
  end
end
