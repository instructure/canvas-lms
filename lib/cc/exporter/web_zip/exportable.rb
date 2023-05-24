# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

module CC::Exporter::WebZip
  module Exportable
    def content_cartridge
      attachment
    end

    def create_zip(exporter, progress_key)
      CC::Exporter::WebZip::ZipPackage.new(exporter, course, user, progress_key)
    end

    def convert_to_offline_web_zip(progress_key)
      exporter = CC::Exporter::WebZip::Exporter.new(content_cartridge.open,
                                                    false,
                                                    :web_zip,
                                                    global_identifiers: content_export.global_identifiers?)
      zip = create_zip(exporter, progress_key)
      file_path = zip.create

      exporter.cleanup_files
      zip.cleanup_files

      file_path
    end
  end
end
