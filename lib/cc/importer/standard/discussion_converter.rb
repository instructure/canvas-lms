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
  module DiscussionConverter
    include CC::Importer

    def convert_discussions
      topics = []

      resources_by_type("imsdt").each do |res|
        topic = {:migration_id => res[:migration_id]}
        path = res[:href] || res[:files].first[:href]
        path = get_full_path(path)

        if File.exists?(path)
          doc = open_file_xml(path)
          doc.remove_namespaces! unless doc.namespaces['xmlns']
          topic[:description] = get_node_val(doc, 'text')
          topic[:description] = replace_urls(topic[:description])
          topic[:title] = get_node_val(doc, 'title')

          if doc.css('attachment').length > 1
            # canvas discussions only support one attachment, so just list them at the bottom of the description
            topic[:description] += "\n<ul>"
            doc.css('attachment').each do |att_node|
              att_path = att_node['href']
              topic[:description] +="\n<li><a href=\"#{get_canvas_att_replacement_url(att_path)}\">#{File.basename att_path}</a>"
            end
            topic[:description] += "\n</ul>"
          elsif att_node = doc.at_css('attachment')
            path = att_node['href']
            if id = find_file_migration_id(path)
              topic[:attachment_migration_id] = id
            end
          end
          topics << topic
        end
      end

      topics
    end

  end
end
