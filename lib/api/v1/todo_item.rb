# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

module Api::V1::TodoItem
  include Api::V1::Assignment
  include Api::V1::Quiz
  include Api::V1::Context

  def todo_item_json(assignment_or_quiz, user, session, todo_type, include_grading_counts: false)
    context_data(assignment_or_quiz).merge({
                                             context_name: assignment_or_quiz&.context&.name,
                                             context_short_name: assignment_or_quiz&.context&.short_name,
                                             type: todo_type,
                                             ignore: api_v1_users_todo_ignore_url(assignment_or_quiz.asset_string, todo_type, permanent: "0"),
                                             ignore_permanently: api_v1_users_todo_ignore_url(assignment_or_quiz.asset_string, todo_type, permanent: "1"),
                                           }).tap do |hash|
      if assignment_or_quiz.is_a?(Quizzes::Quiz)
        quiz = assignment_or_quiz
        hash[:quiz] = quiz_json(quiz, quiz.context, user, session)
        hash[:html_url] = course_quiz_url(quiz.context_id, quiz.id)
      else
        assignment = assignment_or_quiz
        hash[:assignment] = assignment_json(assignment, user, session, include_all_dates: true)

        # Add checkpoint-specific data for SubAssignments
        if assignment.is_a?(SubAssignment)
          hash[:checkpoint_label] = assignment.sub_assignment_tag
          hash[:parent_assignment_id] = assignment.parent_assignment_id
        end

        hash[:html_url] = if todo_type == "grading"
                            speed_grader_course_gradebook_url(assignment.context_id, assignment_id: assignment.id)
                          else
                            "#{course_assignment_url(assignment.context_id, assignment.id)}#submit"
                          end

        if todo_type == "grading"
          hash["needs_grading_count"] = Assignments::NeedsGradingCountQuery.new([assignment], user).count[assignment.global_id]

          if include_grading_counts && @domain_root_account&.feature_enabled?(:educator_dashboard)
            metrics = Assignments::TeacherTodoMetricsQuery.new(assignment, user).metrics
            hash["on_time_needs_grading_count"] = metrics[:on_time_needs_grading_count]
            hash["late_needs_grading_count"] = metrics[:late_needs_grading_count]
            hash["resubmitted_needs_grading_count"] = metrics[:resubmitted_needs_grading_count]
            hash["submitted_submissions_count"] = metrics[:submitted_submissions_count]
            hash["total_submissions_count"] = metrics[:total_submissions_count]
          end
        end
      end
    end
  end
end
