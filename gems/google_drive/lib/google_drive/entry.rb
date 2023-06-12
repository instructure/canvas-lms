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
#
module GoogleDrive
  class Entry
    attr_reader :document_id, :folder, :entry

    def initialize(google_drive_entry, preferred_extensions = nil)
      @entry = google_drive_entry
      @document_id = @entry["id"]
      @preferred_extensions = preferred_extensions
      parent = @entry["parents"].empty? ? nil : @entry["parents"][0]
      @folder = ((parent.nil? || parent["isRoot"]) ? nil : parent["id"])
    end

    def alternate_url
      @entry["alternateLink"] || "http://docs.google.com"
    end

    def edit_url
      alternate_url rescue "https://docs.google.com/document/d/#{@document_id}/edit?usp=drivesdk"
    end

    def extension
      file_data[:ext]
    end

    def display_name
      @entry["title"] || "google_doc.#{extension}"
    end

    def download_url
      file_data[:url]
    end

    def to_hash
      {
        name: display_name,
        document_id: @document_id,
        extension:,
        alternate_url: { href: alternate_url }
      }
    end

    private

    def file_data
      # First we check export links for our preferred formats
      # then we fail over to the file properties
      if @entry["exportLinks"]
        url, extension = preferred_export_link @preferred_extensions
      end

      # we'll have to find the url and extensions some other place
      extension ||= @entry["fileExtension"] if @entry.key? "fileExtension"
      extension ||= "none"

      url ||= @entry["downloadUrl"] if @entry.key? "downloadUrl"

      {
        url:,
        ext: extension
      }
    end

    def preferred_export_link(preferred_extensions = nil)
      preferred_urls = preferred_mime_types.map do |mime_type|
        next unless @entry["exportLinks"][mime_type]

        current_url = @entry["exportLinks"][mime_type]
        current_extension = /([a-z]+)$/.match(current_url).to_s
        has_preferred_extension = preferred_extensions&.include?(current_extension)

        # our extension is in the preferred list or we have no preferences
        [current_url, current_extension] if has_preferred_extension || !preferred_extensions
      end

      url, extension = preferred_urls.find { |i| i }

      # if we dont have any "preferred extension" just return the default.
      # they will be filtered out by the folderize method
      return preferred_export_link if url.nil? && preferred_extensions

      [url, extension]
    end

    def preferred_mime_types
      # Order is important
      # we return the first matching mime type
      %w[
        application/vnd.openxmlformats-officedocument.wordprocessingml.document
        application/vnd.oasis.opendocument.text
        application/vnd.openxmlformats-officedocument.presentationml.presentation
        application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
        application/x-vnd.oasis.opendocument.spreadsheet
        application/pdf
        application/zip
      ]
    end
  end
end
