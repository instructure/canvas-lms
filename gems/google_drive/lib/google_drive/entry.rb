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
    attr_reader :folder, :file

    def initialize(file, preferred_extensions = nil)
      @file = file
      @preferred_extensions = preferred_extensions
      parent = file.parents.first
      @folder = ((parent.nil? || parent["isRoot"]) ? nil : parent["id"])
    end

    def document_id = @file.id

    def alternate_url
      @file.alternate_link || "http://docs.google.com"
    end
    alias_method :edit_url, :alternate_url

    def extension
      file_data[:ext]
    end

    def display_name
      @file.name || "google_doc.#{extension}"
    end

    def download_url
      file_data[:url]
    end

    def to_hash
      {
        name: display_name,
        document_id:,
        extension:,
        alternate_url: { href: alternate_url }
      }
    end

    private

    def file_data
      # First we check export links for our preferred formats
      # then we fail over to the file properties
      if @file.export_links && !@file.export_links.empty?
        url, extension = preferred_export_link @preferred_extensions
      end

      # we'll have to find the url and extensions some other place
      extension ||= @file.file_extension
      extension ||= "none"

      url ||= @file.web_content_link

      {
        url:,
        ext: extension
      }
    end

    def preferred_export_link(preferred_extensions = nil)
      preferred_mime_types.each do |mime_type|
        next unless (current_url = @file.export_links[mime_type])

        current_extension = /([a-z]+)$/.match(current_url).to_s
        has_preferred_extension = preferred_extensions&.include?(current_extension)

        # our extension is in the preferred list or we have no preferences
        return [current_url, current_extension] if has_preferred_extension || !preferred_extensions
      end

      # if we dont have any "preferred extension" just return the default.
      # they will be filtered out by the folderize method
      return preferred_export_link if preferred_extensions

      [nil, nil]
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
