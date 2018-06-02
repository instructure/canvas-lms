#
# Copyright (C) 2017 - present Instructure, Inc.
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

require 'English'

module Exporters
  class Quizzes2Exporter

    GROUP_NAME = 'Migrated Quizzes'.freeze

    attr_accessor :course, :quiz
    delegate :add_error, :to => :@content_export, :allow_nil => true

    def initialize(content_export)
      @content_export = content_export
      @course = @content_export.context
      @context_id = @course.id
      @quiz = @course.quizzes.find(content_export.selected_content)
      # TO-DO: we need pass in the ID of the
      # quiz from the view, which is not hooked up yet
    end

    def build_assignment_payload
      {
        assignment: {
          resource_link_id: @assignment.lti_resource_link_id,
          title: @quiz.title,
          context_title: @quiz.context.name,
          course_uuid: @course.uuid
        }
      }
    end

    def export
      begin
        create_assignment
      rescue
        add_error(I18n.t("Error running Quizzes 2 export."), $ERROR_INFO)
        return false
      end
      true
    end

    private

    def assignment_group
      @assignment_group ||=
        course.assignment_groups.find_or_create_by(
          name: GROUP_NAME,
          workflow_state: 'available'
        )
    end

    def create_assignment
      post_to_sis = Assignment.sis_grade_export_enabled?(course)
      assignment_params = {
        title: quiz.title,
        points_possible: quiz.points_possible,
        due_at: quiz.due_at,
        unlock_at: quiz.unlock_at,
        lock_at: quiz.lock_at,
        assignment_group: assignment_group,
        workflow_state: 'unpublished'
      }
      assignment_params[:post_to_sis] = quiz.assignment.post_to_sis if quiz.assignment && post_to_sis
      assignment = course.assignments.create(assignment_params)
      assignment.quiz_lti! && assignment.save!
      @assignment = assignment
    end
  end
end
