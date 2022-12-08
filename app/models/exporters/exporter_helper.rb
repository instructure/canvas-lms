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

module Exporters
  module ExporterHelper
    def self.add_attachment_to_zip(attachment, zipfile, filename = nil, files_in_zip = [])
      filename ||= attachment.filename

      # we allow duplicate filenames in the same folder. it's a bit silly, but we
      # have to handle it here or people might not get all their files zipped up.
      filename = Attachment.make_unique_filename(filename, files_in_zip)
      files_in_zip << filename

      handle = nil
      begin
        handle = attachment.open
        zipfile.get_output_stream(filename) { |zos| Zip::IOExtras.copy_stream(zos, handle) }
      rescue
        return false
      ensure
        handle&.close
      end

      true
    end
  end
end
