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

module CC::Exporter::Epub::Converters
  module AssignmentEpubConverter
    include CC::Exporter

    def convert_assignments
      assignments = []
      @manifest.css('resource[type$=learning-application-resource]').each do |res|
        meta_path = res.at_css('file[href$="assignment_settings.xml"]')
        next unless meta_path

        meta_path = @package_root.item_path meta_path['href']
        html_path = @package_root.item_path res.at_css('file[href$="html"]')['href']

        meta_node = open_file_xml(meta_path)
        html_node = open_file(html_path)

        assignment = assignment_data(meta_node, html_node)
        next unless include_item?(meta_node)
        assignments << assignment
      end
      assignments
    end

    def assignment_data(meta_doc, html_doc=nil)
      assignment = {}
      if html_doc
        _title, body = get_html_title_and_body(html_doc)
        assignment[:description] = body
      end
      [:title, :allowed_extensions].each do |string_type|
        val = get_node_val(meta_doc, string_type)
        assignment[string_type] = val unless val.nil?
      end
      [:due_at, :lock_at, :unlock_at].each do |date_type|
        val = get_node_val(meta_doc, date_type)
        assignment[date_type] = val unless val.nil?
      end
      [:points_possible].each do |f_type|
        val = get_float_val(meta_doc, f_type)
        assignment[f_type] = val unless val.nil?
      end
      assignment[:grading_type] = CartridgeConverter::ALLOWED_GRADING_TYPES[get_node_val(meta_doc, :grading_type)]
      assignment[:submission_types] = submission_types(get_node_val(meta_doc, :submission_types))
      assignment[:position] = get_node_val(meta_doc, 'position')
      assignment[:identifier] = get_node_att(meta_doc, 'assignment', 'identifier')
      assignment[:href] = "assignments.xhtml##{assignment[:identifier]}"
      update_syllabus(assignment)
      assignment
    end

    def submission_types(types)
      return [] unless types.present?
      types.split(",").map{|sub_type| CartridgeConverter::SUBMISSION_TYPES[sub_type]}
    end
  end
end
