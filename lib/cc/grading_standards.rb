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
module CC
  module GradingStandards
    def add_referenced_grading_standards
      @course.assignments.active.where('grading_standard_id IS NOT NULL').each do |assignment|
        next unless export_object?(assignment) ||
            assignment.quiz && export_object?(assignment.quiz) ||
            assignment.discussion_topic && export_object?(assignment.discussion_topic)
        gs = assignment.grading_standard
        add_item_to_export(gs) if gs && gs.context_type == 'Course' && gs.context_id == @course.id
      end
    end

    def create_grading_standards(document=nil)
      add_referenced_grading_standards if for_course_copy
      standards_to_copy = (@course.grading_standards.to_a + [@course.grading_standard]).compact.uniq(&:id).select{|s| export_object?(s)}
      return nil unless standards_to_copy.size > 0
      
      if document
        standards_file = nil
        rel_path = nil
      else
        standards_file = File.new(File.join(@canvas_resource_dir, CCHelper::GRADING_STANDARDS), 'w')
        rel_path = File.join(CCHelper::COURSE_SETTINGS_DIR, CCHelper::GRADING_STANDARDS)
        document = Builder::XmlMarkup.new(:target=>standards_file, :indent=>2)
      end
      
      document.instruct!
      document.gradingStandards(
              "xmlns" => CCHelper::CANVAS_NAMESPACE,
              "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
              "xsi:schemaLocation"=> "#{CCHelper::CANVAS_NAMESPACE} #{CCHelper::XSD_URI}"
      ) do |standards_node|
        standards_to_copy.each do |standard|
          migration_id = CCHelper.create_key(standard)
          standards_node.gradingStandard(:identifier=>migration_id, :version=>standard.version) do |standard_node|
            standard_node.title standard.title unless standard.title.blank?
            standard_node.data standard.data.to_json
          end
        end
      end
      
      standards_file.close if standards_file
      rel_path
    end
  end
end
