#
# Copyright (C) 2011 Instructure, Inc.
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
module GoogleDocs
  class DriveEntry

    attr_reader :document_id, :folder, :entry

    def initialize(google_drive_entry)
      @entry = google_drive_entry
      @document_id = @entry['id']
      parent = @entry['parents'].length > 0 ? @entry['parents'][0] : nil
      @folder = (parent == nil || parent['isRoot'] ? nil : parent['id'])
    end

    def alternate_url
      @entry['alternateLink'] || 'http://docs.google.com'
    end

    def edit_url
      alternate_url rescue "https://docs.google.com/document/d/#{@document_id}/edit?usp=drivesdk"
    end


    def self.get_file_data(file)

      # Order is important.

      file_ext = {
          #documents
          'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          'doc' => 'application/vnd.oasis.opendocument.text',

          #presentations
          'pptx' => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',

          #sheets
          'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          'xls' => 'application/x-vnd.oasis.opendocument.spreadsheet',

          #PDF
          'pdf' => 'application/pdf',

          #zip
          'zip' => 'application/zip',
      }

      e = file_ext.find do |extension, mime_type|

        (file['exportLinks'] && file['exportLinks'][mime_type]) ||
        (file['downloadUrl'] && mime_type.match(file['mimeType']))

      end
      if e.present?
        {
            url: (file['exportLinks'] && file['exportLinks'][e.last]) || file['downloadUrl'],
            ext: e.first
        }
      else
        {
            url: file['downloadUrl'],
            ext: 'none'
        }
      end
    end


    def extension
      GoogleDocs::DriveEntry.get_file_data(@entry)[:ext]
    end

    def display_name
      @entry['title'] || "google_doc.#{extension}"
    end

    def download_url
      GoogleDocs::DriveEntry.get_file_data(@entry)[:url]
    end

    def to_hash
      {
        :name => display_name,
        :document_id => @document_id,
        :extension => extension,
        :alternate_url => {:href => alternate_url}
      }
    end

  end
end
