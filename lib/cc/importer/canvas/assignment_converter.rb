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
    
    def convert_assignments
      assignments = []
      
      @manifest.css('resource[type$=learning-application-resource]').each do |res|
        if meta_path = res.at_css('file[href$="assignment_settings.xml"]')
          meta_path = File.join @unzipped_file_path, meta_path['href']
          html_path = File.join @unzipped_file_path, res.at_css('file[href$="html"]')['href']
          
          meta_node = open_file_xml(meta_path)
          html_node = open_file(html_path)
          
          assignments << convert_assignment(meta_node, html_node)
        end
      end
      
      assignments
    end
    
    def convert_assignment(meta_doc, html_doc=nil)
      assignment = {}
      if html_doc
        title, body = get_html_title_and_body(html_doc)
        assignment['description'] = body
      end
      
      assignment['migration_id'] = get_node_att(meta_doc, 'assignment', 'identifier')
      assignment['migration_id'] ||= meta_doc['identifier']
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
      ["turnitin_enabled", "peer_reviews_assigned", "peer_reviews",
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
