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
class Entry
  def self.extension_looker_upper
    @extension_looker_upper
  end

  def self.extension_looker_upper=(extension_looker_upper)
    @extension_looker_upper=extension_looker_upper
  end

  attr_reader :document_id, :folder, :entry

  def initialize(entry)
    if entry.is_a?(String)
      @entry = Atom::Entry.load_entry(entry)
    else
      @entry = entry
    end
    set_document_id_from @entry
    @folder = @entry.categories.find { |c| c.scheme.match(/\Ahttp:\/\/schemas.google.com\/docs\/2007\/folders/) }.label rescue nil
  end

  def alternate_url
    link = @entry.links.find { |link| link.rel == "alternate" && link.type == "text/html" }
    link || "http://docs.google.com"
  end

  def edit_url
    "https://docs.google.com/feeds/documents/private/full/#{@document_id}"
  end

  def content_type
    @entry.content && @entry.content.type
  end

  def extension
    if @extension.nil?
      # first, try and chose and extension by content-types we can scribd
      if !content_type.nil? && !content_type.strip.empty? && self.class.extension_looker_upper && mimetype = self.class.extension_looker_upper.find_by_name(content_type)
        @extension = mimetype.extension
      end
      # second, look at the document id itself for any clues
      if !@document_id.nil? && !@document_id.strip.empty?
        @extension ||= case @document_id
                         when /\Aspreadsheet/ then
                           "xls"
                         when /\Apresentation/ then
                           "ppt"
                         when /\Adocument/ then
                           "doc"
                       end
      end
      # finally, just declare it unknown
      @extension ||= "unknown"
    end
    @extension == "unknown" ? nil : @extension
  end

  def display_name
    @entry.title || "google_doc.#{extension}"
  end

  def download_url
    @entry.content.src
  end

  def to_hash
    {
      "name" => display_name,
      "document_id" => @document_id,
      "extension" => extension,
      "alternate_url" => alternate_url
    }
  end

  private

  def set_document_id_from(entry)
    doc_id = entry.simple_extensions["{http://schemas.google.com/g/2005,resourceId}"]
    @document_id = doc_id.first.to_s
  end
end
end