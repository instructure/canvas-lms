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
module CC::Importer
  module CourseSettings
    include CC::Importer
    
    def course_settings_doc(file)
      open_file_xml File.join(@unzipped_file_path, COURSE_SETTINGS_DIR, file)
    end
    
    def convert_non_dependant_course_settings
      @course[:course] = convert_course_settings(course_settings_doc(COURSE_SETTINGS))
      @course[:assignment_groups] = convert_assignment_groups(course_settings_doc(ASSIGNMENT_GROUPS))
      @course[:external_tools] = convert_external_tools(course_settings_doc(EXTERNAL_TOOLS))
    end

    def convert_course_settings(doc)
      course = {}
      return course unless doc
      course[:migration_id] = get_node_att(doc, 'course',  'identifier')

      ['title', 'course_code', 'hashtag', 'default_wiki_editing_roles',
       'turnitin_comments', 'default_view', 'license',
       'group_weighting_scheme'].each do |string_type|
        val = get_node_val(doc, string_type)
        course[string_type] = val unless val.nil?
      end
      ['is_public', 'indexed', 'publish_grades_immediately', 'allow_student_wiki_edits',
       'allow_student_assignment_edits', 'show_public_context_messages',
       'allow_student_forum_attachments', 'allow_student_organized_groups',
       'show_all_discussion_entries', 'open_enrollment', 'allow_wiki_comments',
       'self_enrollment'].each do |bool_val|
        val = get_bool_val(doc, bool_val)
        course[bool_val] = val unless val.nil?
      end
      ['start_at', 'conclude_at'].each do |date_type|
        val = get_time_val(doc, date_type)
        course[date_type] = val unless val.nil?
      end

      course['storage_quota'] = get_int_val(doc, 'storage_quota')
      
      course
    end

    def convert_assignment_groups(doc = nil)
      groups = []
      return groups unless doc
      doc.css('assignmentGroup').each do |node|
        group = {}
        group['migration_id'] = node['identifier']
        group['title'] = get_node_val(node, 'title')
        group['position'] = get_int_val(node, 'position')
        group['group_weight'] = get_float_val(node, 'group_weight')
        group['rules'] = []
        node.css('rules rule').each do |r_node|
          rule = {}
          rule['drop_type'] = get_node_val(r_node, 'drop_type')
          rule['drop_count'] = get_int_val(r_node, 'drop_count')
          rule['assignment_migration_id'] = get_node_val(r_node, 'identifierref')
          group['rules'] << rule
        end
        
        groups << group
      end
      
      groups
    end

    def convert_external_tools(doc)
      tools = []
      return tools unless doc
      doc.css('externalTool').each do |node|
        tool = {}
        tool['migration_id'] = node['identifier']
        tool['title'] = get_node_val(node, 'title')
        tool['description'] = get_node_val(node, 'description')
        tool['domain'] = get_node_val(node, 'domain')
        tool['url'] = get_node_val(node, 'url')
        tool['privacy_level'] = get_node_val(node, 'privacy_level')
        
        tools << tool
      end

      tools
    end

  end
end