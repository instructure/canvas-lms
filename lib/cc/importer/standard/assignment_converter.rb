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

    def convert_cc_assignments(asmnts=[])
      resources_by_type("assignment", "assignment_xmlv1p0").each do |res|
        if doc = get_node_or_open_file(res, 'assignment')
          path = res[:href] || (res[:files] && res[:files].first && res[:files].first[:href])
          resource_dir = File.dirname(path) if path
          
          asmnt = {:migration_id => res[:migration_id]}.with_indifferent_access
          if res[:intended_user_role] == 'Instructor'
            asmnt[:workflow_state] = 'unpublished'
          end
          parse_cc_assignment_data(asmnt, doc, resource_dir)

          # FIXME check the XML namespace to make sure it's actually a canvas assignment
          # (blocked by remove_namespaces! in lib/canvas/migration/migrator.rb)
          if assgn_node = doc.at_css('extensions > assignment')
            parse_canvas_assignment_data(assgn_node, nil, asmnt)
          end

          asmnts << asmnt
        end
      end

      asmnts
    end

    def parse_cc_assignment_data(asmnt, doc, resource_dir)
      asmnt[:description] = get_node_val(doc, 'text')
      asmnt[:description] = replace_urls(asmnt[:description]) unless @canvas_converter
      asmnt[:instructor_description] = get_node_val(doc, 'instructor_text')
      asmnt[:title] = get_node_val(doc, 'title')
      asmnt[:gradable] = get_bool_val(doc, 'gradable')
      if points_possible = get_node_att(doc, 'gradable', 'points_possible')
        asmnt[:grading_type] = 'points'
        asmnt[:points_possible] = points_possible.to_f
      end
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
          url = @canvas_converter ? att_path : (get_canvas_att_replacement_url(att_path, resource_dir) || att_path)
          asmnt[:description] +="\n<li><a href=\"#{url}\">#{File.basename att_path}</a>"
        end
        asmnt[:description] += "\n</ul>"
      end
    end

    def parse_canvas_assignment_data(meta_doc, html_doc=nil, assignment = {})
      if html_doc
        title, body = get_html_title_and_body(html_doc)
        assignment['description'] = body
      end

      assignment["migration_id"] ||= get_node_att(meta_doc, 'assignment', 'identifier') || meta_doc['identifier']
      assignment["assignment_group_migration_id"] = get_node_val(meta_doc, "assignment_group_identifierref")
      assignment["grading_standard_migration_id"] = get_node_val(meta_doc, "grading_standard_identifierref")
      assignment["rubric_migration_id"] = get_node_val(meta_doc, "rubric_identifierref")
      assignment["rubric_id"] = get_node_val(meta_doc, "rubric_external_identifier")
      assignment["quiz_migration_id"] = get_node_val(meta_doc, "quiz_identifierref")
      assignment["workflow_state"] = get_node_val(meta_doc, "workflow_state") if meta_doc.at_css("workflow_state")
      if meta_doc.at_css("saved_rubric_comments comment")
        assignment[:saved_rubric_comments] = {}
        meta_doc.css("saved_rubric_comments comment").each do |comment_node|
          assignment[:saved_rubric_comments][comment_node['criterion_id']] ||= []
          assignment[:saved_rubric_comments][comment_node['criterion_id']] << comment_node.text.strip
        end
      end
      ['title', "allowed_extensions", "grading_type", "submission_types", "external_tool_url"].each do |string_type|
        val = get_node_val(meta_doc, string_type)
        assignment[string_type] = val unless val.nil?
      end
      ["turnitin_enabled", "peer_reviews",
       "automatic_peer_reviews", "anonymous_peer_reviews", "freeze_on_copy",
       "grade_group_students_individually", "external_tool_new_tab",
       "rubric_use_for_grading", "rubric_hide_score_total", "muted"].each do |bool_val|
        val = get_bool_val(meta_doc, bool_val)
        assignment[bool_val] = val unless val.nil?
      end
      ['due_at', 'lock_at', 'unlock_at', 'peer_reviews_due_at'].each do |date_type|
        val = get_time_val(meta_doc, date_type)
        assignment[date_type] = val unless val.nil?
      end
      ['points_possible'].each do |f_type|
        val = get_float_val(meta_doc, f_type)
        assignment[f_type] = val unless val.nil?
      end
      assignment['position'] = get_int_val(meta_doc, 'position')
      assignment['peer_review_count'] = get_int_val(meta_doc, 'peer_review_count')

      assignment
    end
  end
end
