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
module CC::Importer::Standard
  module WeblinkConverter
    include CC::Importer
    def get_weblink_title_and_url(resource)
      title = ''
      url = ''
      if resource[:files] && resource[:files].first
        path = get_full_path(resource[:files].first[:href])
        if File.exists?(path)
          xml = open(path).read
          # because of some sadness from certain vendors clear empty namespace declarations
          xml.gsub!(/xmlns=""/, '')
          doc = create_xml_doc(xml)
          doc.remove_namespaces! unless doc.namespaces['xmlns']
          title = get_node_val(doc, 'webLink title')
          url = get_node_att(doc, 'webLink url', 'href')
        end
      elsif doc = get_node_or_open_file(resource, 'webLink')
        title = get_node_val(doc, 'title')
        url = get_node_att(doc, 'url', 'href')
      end
      [title, url]
    end
  end
end
