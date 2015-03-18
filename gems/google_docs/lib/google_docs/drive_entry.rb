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

    def initialize(google_drive_entry, preferred_extensions=nil)
      @entry = google_drive_entry
      @document_id = @entry['id']
      @preferred_extensions = preferred_extensions
      parent = @entry['parents'].length > 0 ? @entry['parents'][0] : nil
      @folder = (parent == nil || parent['isRoot'] ? nil : parent['id'])
    end

    def alternate_url
      @entry['alternateLink'] || 'http://docs.google.com'
    end

    def edit_url
      alternate_url rescue "https://docs.google.com/document/d/#{@document_id}/edit?usp=drivesdk"
    end

    def extension
      get_file_data[:ext]
    end

    def display_name
      @entry['title'] || "google_doc.#{extension}"
    end

    def download_url
      get_file_data[:url]
    end

    def to_hash
      {
        :name => display_name,
        :document_id => @document_id,
        :extension => extension,
        :alternate_url => {:href => alternate_url}
      }
    end

    private
    def get_file_data()
      # First we check export links for our preferred formats
      # then we fail over to the file properties
      if @entry['exportLinks']
        url, extension = preferred_export_link @preferred_extensions
      end

      # we'll have to find the url and extensions some other place
      extension ||= @entry['fileExtension'] if @entry.has_key? 'fileExtension'
      extension ||= 'none'

      url ||= @entry['downloadUrl'] if @entry.has_key? 'downloadUrl'

      {
        url: url,
        ext: extension
      }
    end

    def preferred_export_link(preferred_extensions=nil)

      # Order is important
      # we return the first matching mime type
      preferred_mime_types = %w{
        application/vnd.openxmlformats-officedocument.wordprocessingml.document
        application/vnd.oasis.opendocument.text
        application/vnd.openxmlformats-officedocument.presentationml.presentation
        application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
        application/x-vnd.oasis.opendocument.spreadsheet
        application/pdf
        application/zip
      }

      url, extension = preferred_mime_types.map do |mime_type|
        next unless @entry['exportLinks'][mime_type]

        current_url = @entry['exportLinks'][mime_type]
        current_extension = /([a-z]+)$/.match(current_url).to_s

        # our extension is in the preferred list or we have no preferences
        [current_url, current_extension] if (preferred_extensions && preferred_extensions.include?(current_extension)) || !preferred_extensions
      end.find{|i|i}

      # if we dont have any "preferred extension" just return the default.
      # they will be filtered out by the folderize method
      return preferred_export_link if url == nil && preferred_extensions
      [url, extension]
    end

  end
end
