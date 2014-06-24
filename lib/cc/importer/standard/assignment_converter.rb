#
# Copyright (C) 2013 Instructure, Inc.
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
  module AssignmentConverter
    include CC::Importer

    def convert_assignments(asmnts=[])
      resources_by_type("assignment", "assignment_xmlv1p0").each do |res|
        path = res[:href] || (res[:files] && res[:files].first && res[:files].first[:href])
        resource_dir = File.dirname(path) if path

        if doc = get_node_or_open_file(res, 'assignment')
          asmnt = {:migration_id => res[:migration_id]}
          asmnt[:description] = get_node_val(doc, 'text')
          asmnt[:description] = replace_urls(asmnt[:description])
          asmnt[:instructor_description] = get_node_val(doc, 'instructor_text')
          asmnt[:title] = get_node_val(doc, 'title')
          asmnt[:gradable] = get_bool_val(doc, 'gradable')
          if doc.css('submission_formats format').length > 0
            asmnt[:submission_types] = []
            doc.css('submission_formats format').each do |format|
              type = format['type']
              type = 'online_text_entry' if type == 'text'
              type = 'online_text_entry' if type == 'html'
              type = 'online_url' if type == 'url'
              type = 'online_upload' if type == 'file'
              asmnt[:submission_types] << type
            end
            asmnt[:submission_types] = asmnt[:submission_types].uniq.join ','
          end

          if doc.css('attachment')
            asmnt[:description] += "\n<ul>"
            doc.css('attachment').each do |att_node|
              #todo next if type is teachers
              att_path = att_node['href']
              asmnt[:description] +="\n<li><a href=\"#{get_canvas_att_replacement_url(att_path, resource_dir) || att_path}\">#{File.basename att_path}</a>"
            end
            asmnt[:description] += "\n</ul>"
          end

          asmnts << asmnt
        end
      end

      asmnts
    end
  end
end
