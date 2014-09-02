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
module CC::Importer::Canvas
  module AssignmentConverter
    include CC::Importer
    include CC::Importer::Standard::AssignmentConverter
    
    def convert_canvas_assignments
      assignments = convert_cc_assignments

      @manifest.css('resource[type$=learning-application-resource]').each do |res|
        if meta_path = res.at_css('file[href$="assignment_settings.xml"]')
          meta_path = File.join @unzipped_file_path, meta_path['href']
          html_path = File.join @unzipped_file_path, res.at_css('file[href$="html"]')['href']
          
          meta_node = open_file_xml(meta_path)
          html_node = open_file(html_path)

          mig_id = get_node_att(meta_node, 'assignment', 'identifier') || meta_node['identifier']
          assignment = assignments.detect{|a| a['migration_id'] && a['migration_id'] == mig_id}
          unless assignment
            assignment = {'migration_id' => mig_id}.with_indifferent_access
            assignments << assignment
          end

          parse_canvas_assignment_data(meta_node, html_node, assignment)
        end
      end

      assignments
    end

  end
end
