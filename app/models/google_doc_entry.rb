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

class GoogleDocEntry
  attr_accessor :document_id, :folder, :entry
  def initialize(entry)
    @entry = entry
    if entry.is_a?(String)
      @entry = Atom::Entry.load_entry(entry)
    end
    @document_id = @entry.simple_extensions["{http://schemas.google.com/g/2005,resourceId}"].to_s
    @folder = @entry.categories.find{|c| c.scheme.match(/\Ahttp:\/\/schemas.google.com\/docs\/2007\/folders/)}.label rescue nil
  end
  
  def alternate_url
    link = @entry.links.find{|link| link.rel == "alternate" && link.type == "text/html"}
    link || "http://docs.google.com"
  end
  
  def edit_url
    "http://docs.google.com/feeds/documents/private/full/#{@document_id}"
  end
  
  def extension
    case @document_id
    when /\Aspreadsheet/ then "xls"
    when /\Apresentation/ then "ppt"
    when /\Adocument/ then "doc"
    else
      case @entry.content.type
      # TODO more of these
      when 'application/pdf' then 'pdf'
      else nil
      end
    end
  end

  def display_name
    @entry.title || "google_doc.#{extension}"
  end

  def download_url
    @entry.content.src
  end
end
