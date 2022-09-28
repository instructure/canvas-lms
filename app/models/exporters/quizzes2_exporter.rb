# frozen_string_literal: true

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

require "English"

module Exporters
  class Quizzes2Exporter
    GROUP_NAME = "Migrated Quizzes"

    attr_accessor :course, :quiz

    delegate :add_error, to: :@content_export, allow_nil: true

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
          assignment_id: @assignment.global_id,
          title: @quiz.title,
          context_title: @quiz.context.name,
          course_uuid: @course.uuid,
          points_possible: @assignment.points_possible
        }
      }
    end

    def export(opts = {})
      begin
        failed_assignment_id = opts[:failed_assignment_id]
        failed_assignment = Assignment.find_by(id: failed_assignment_id)
        create_assignment(failed_assignment)
      rescue
        add_error(I18n.t("Error running Quizzes 2 export."), $ERROR_INFO)
        return false
      end
      true
    end

    private

    def assignment_group(failed_assignment)
      return @_assignment_group if @_assignment_group.present?

      if failed_assignment.present?
        @_assignment_group = failed_assignment.assignment_group
        return @_assignment_group if @_assignment_group.present?
      end

      @_assignment_group = course.assignment_groups.find_or_create_by(
        name: GROUP_NAME,
        workflow_state: "available"
      )
    end

    def create_assignment(failed_assignment)
      post_to_sis = Assignment.sis_grade_export_enabled?(course)
      params = assignment_params(failed_assignment)

      params[:post_to_sis] = quiz.assignment.post_to_sis if quiz.assignment && post_to_sis
      assignment = course.assignments.create(params)
      assignment.quiz_lti! && assignment.save!
      @assignment = assignment
    end

    def assignment_params(failed_assignment)
      params = {
        title: quiz.title,
        points_possible: quiz.points_possible,
        due_at: quiz.due_at,
        unlock_at: quiz.unlock_at,
        lock_at: quiz.lock_at,
        assignment_group: assignment_group(failed_assignment),
        workflow_state: new_quizzes_page_enabled? ? "migrating" : "unpublished",
        duplication_started_at: Time.zone.now,
        migrate_from_id: @quiz.id
      }
      params[:position] = failed_assignment.position if failed_assignment.present?
      params
    end

    def new_quizzes_page_enabled?
      @course.root_account.feature_enabled?(:newquizzes_on_quiz_page)
    end
  end
end
