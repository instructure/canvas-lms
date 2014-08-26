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
  module AssignmentResources
    
    def add_assignments
      @course.assignments.active.no_graded_quizzes_or_topics.each do |assignment|
        next unless export_object?(assignment)

        title = assignment.title rescue I18n.t('course_exports.unknown_titles.assignment', "Unknown assignment")

        if !assignment.can_copy?(@user)
          add_error(I18n.t('course_exports.errors.assignment_is_locked', "The assignment \"%{title}\" could not be copied because it is locked.", :title => title))
          next
        end

        begin
          add_assignment(assignment)
        rescue
          add_error(I18n.t('course_exports.errors.assignment', "The assignment \"%{title}\" failed to export", :title => title), $!)
        end
      end
    end

    VERSION_1_3 = Gem::Version.new('1.3')

    def add_assignment(assignment)
      migration_id = CCHelper.create_key(assignment)

      lo_folder = File.join(@export_dir, migration_id)
      FileUtils::mkdir_p lo_folder

      file_name = "#{assignment.title.to_url}.html"
      path = File.join(lo_folder, file_name)
      html_path = File.join(migration_id, file_name)

      # Write the assignment description as an .html file
      # That way at least the content of the assignment will appear
      # for agents that support neither CC 1.3 nor Canvas assignments
      File.open(path, 'w') do |file|
        file << @html_exporter.html_page(assignment.description || '', "Assignment: " + assignment.title)
      end

      if Gem::Version.new(@manifest.cc_version) >= VERSION_1_3
        add_cc_assignment(assignment, migration_id, lo_folder, html_path)
      else
        add_canvas_assignment(assignment, migration_id, lo_folder, html_path)
      end
    end
    
    def add_cc_assignment(assignment, migration_id, lo_folder, html_path)
      File.open(File.join(lo_folder, CCHelper::ASSIGNMENT_XML), 'w') do |assignment_file|
        document = Builder::XmlMarkup.new(:target => assignment_file, :indent => 2)
        document.instruct!

        document.assignment("identifier" => migration_id,
                            "xmlns" => CCHelper::ASSIGNMENT_NAMESPACE,
                            "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
                            "xsi:schemaLocation"=> "#{CCHelper::ASSIGNMENT_NAMESPACE} #{CCHelper::ASSIGNMENT_XSD_URI}"
        ) do |a|
          AssignmentResources.create_cc_assignment(a, assignment, migration_id, @manifest)
        end
      end

      xml_path = File.join(migration_id, CCHelper::ASSIGNMENT_XML)
      @resources.resource(:identifier => migration_id,
                          :type => CCHelper::ASSIGNMENT_TYPE,
                          :href => xml_path
      ) do |res|
        res.file(:href => xml_path)
      end

      @resources.resource(:identifier => migration_id + "_fallback",
                          :type => CCHelper::WEBCONTENT
      ) do |res|
        res.tag!('cpx:variant', :identifier => migration_id + "_variant",
                                :identifierref => migration_id
        ) do |var|
          var.tag!('cpx:metadata')
        end
        res.file(:href => html_path)
      end
    end
    
    def add_canvas_assignment(assignment, migration_id, lo_folder, html_path)
      assignment_file = File.new(File.join(lo_folder, CCHelper::ASSIGNMENT_SETTINGS), 'w')
      document = Builder::XmlMarkup.new(:target=>assignment_file, :indent=>2)
      document.instruct!

      # Save all the meta-data into a canvas-specific xml schema
      document.assignment("identifier" => migration_id,
                          "xmlns" => CCHelper::CANVAS_NAMESPACE,
                          "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
                          "xsi:schemaLocation"=> "#{CCHelper::CANVAS_NAMESPACE} #{CCHelper::XSD_URI}"
      ) do |a|
        AssignmentResources.create_canvas_assignment(a, assignment, @manifest)
      end
      assignment_file.close

      @resources.resource(
        :identifier => migration_id,
        "type" => CCHelper::LOR,
        :href => html_path
      ) do |res|
        res.file(:href=>html_path)
        res.file(:href=>File.join(migration_id, CCHelper::ASSIGNMENT_SETTINGS))
      end
    end

    SUBMISSION_TYPE_MAP = {
        "online_text_entry" => "html",
        "online_url" => "url",
        "online_upload" => "file"
    }.freeze

    def self.create_cc_assignment(node, assignment, migration_id, manifest = nil)
      node.title(assignment.title)
      node.text(assignment.description, texttype: 'text/html')
      if assignment.points_possible
        node.gradable(assignment.graded?, points_possible: assignment.points_possible)
      else
        node.gradable(assignment.graded?)
      end
      node.submission_formats do |fmt|
        assignment.submission_types.split(',').each do |st|
          if cc_type = SUBMISSION_TYPE_MAP[st]
            fmt.format(:type => cc_type)
          end
        end
      end
      node.extensions do |ext|
        ext.assignment("identifier" => migration_id + "_canvas",
                       "xmlns" => CCHelper::CANVAS_NAMESPACE,
                       "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
                       "xsi:schemaLocation"=> "#{CCHelper::CANVAS_NAMESPACE} #{CCHelper::XSD_URI}"
        ) do |a|
          AssignmentResources.create_canvas_assignment(a, assignment, manifest)
        end
      end
    end

    def self.create_canvas_assignment(node, assignment, manifest = nil)
      node.title assignment.title
      node.due_at CCHelper::ims_datetime(assignment.due_at) if assignment.due_at
      node.lock_at CCHelper::ims_datetime(assignment.lock_at) if assignment.lock_at
      node.unlock_at CCHelper::ims_datetime(assignment.unlock_at) if assignment.unlock_at
      node.all_day_date CCHelper::ims_date(assignment.all_day_date) if assignment.all_day_date
      node.peer_reviews_due_at CCHelper::ims_datetime(assignment.peer_reviews_due_at) if assignment.peer_reviews_due_at
      node.assignment_group_identifierref CCHelper.create_key(assignment.assignment_group) if assignment.assignment_group && (!manifest || manifest.export_object?(assignment.assignment_group))
      node.grading_standard_identifierref CCHelper.create_key(assignment.grading_standard) if assignment.grading_standard && (!manifest || manifest.export_object?(assignment.grading_standard))
      node.workflow_state assignment.workflow_state
      if assignment.rubric
        assoc = assignment.rubric_association
        node.rubric_identifierref CCHelper.create_key(assignment.rubric)
        if assignment.rubric && assignment.rubric.context != assignment.context
          node.rubric_external_identifier assignment.rubric.id
        end
        node.rubric_use_for_grading assoc.use_for_grading
        node.rubric_hide_score_total assoc.hide_score_total
        if assoc.summary_data && assoc.summary_data[:saved_comments]
          node.saved_rubric_comments do |sc_node|
            assoc.summary_data[:saved_comments].each_pair do |key, vals|
              vals.each do |val|
                sc_node.comment(:criterion_id => key){|a|a << val}
              end
            end
          end
        end
      end
      node.quiz_identifierref CCHelper.create_key(assignment.quiz) if assignment.quiz
      node.allowed_extensions assignment.allowed_extensions.join(',') unless assignment.allowed_extensions.blank?
      atts = [:points_possible, :grading_type,
              :all_day, :submission_types, :position, :turnitin_enabled, :peer_review_count,
              :peer_reviews, :automatic_peer_reviews,
              :anonymous_peer_reviews, :grade_group_students_individually, :freeze_on_copy, :muted]
      atts.each do |att|
        node.tag!(att, assignment.send(att)) if assignment.send(att) == false || !assignment.send(att).blank?
      end
      if assignment.external_tool_tag
        node.external_tool_url assignment.external_tool_tag.url 
        node.external_tool_new_tab assignment.external_tool_tag.new_tab
      end
    end

  end
end
