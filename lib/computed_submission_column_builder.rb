# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module ComputedSubmissionColumnBuilder
  def self.add_group_name_column(submission_scope, assignment)
    column = "db_group_name"
    memberships = assignment.group_memberships.select("group_memberships.user_id", "groups.name")
    scope = submission_scope
            .select("submissions.*", "#{Group.best_unicode_collation_key("memberships.name")} AS #{column}")
            .joins("LEFT OUTER JOIN (#{memberships.to_sql}) AS memberships ON memberships.user_id = submissions.user_id")

    { scope:, column: }
  end

  # Adds a computed column indicating whether a submission needs grading by the current user.
  # For moderated assignments, excludes submissions where the current user has already
  # provided a provisional grade with a non-null score.
  #
  # @param submission_scope [ActiveRecord::Relation] Base submission scope to augment
  # @param current_user [User, nil] Current user for moderated grading filtering
  # @return [Hash] Hash with :scope and :column keys
  def self.add_needs_grading_column(submission_scope, current_user = nil)
    column = "db_needs_grading"

    needs_grading_sql = Submission.needs_grading_conditions

    # For moderated assignments, exclude submissions where the current user has already
    # provided a provisional grade (they don't "need" grading from this user anymore)
    if current_user
      needs_grading_sql = <<~SQL.squish
        (#{needs_grading_sql})
        AND (
          assignments.moderated_grading IS FALSE
          OR assignments.grades_published_at IS NOT NULL
          OR NOT EXISTS (
            SELECT 1 FROM #{ModeratedGrading::ProvisionalGrade.quoted_table_name} AS provisional_grades
            WHERE provisional_grades.submission_id = submissions.id
              AND provisional_grades.scorer_id = #{submission_scope.connection.quote(current_user.id)}
              AND provisional_grades.score IS NOT NULL
          )
        )
      SQL
    end

    scope = submission_scope
            .joins(:assignment)
            .select(
              "submissions.*",
              "#{needs_grading_sql} AS #{column}"
            )

    { scope:, column: }
  end

  def self.add_submission_status_column(submission_scope, current_user)
    column = "db_submission_status"
    scope = status_base_scope(submission_scope)
            .select("#{submission_status_conditions(current_user)} AS #{column}")

    { scope:, column: }
  end

  def self.add_submission_status_priority_column(submission_scope, current_user, priorities)
    column = "db_submission_status_priority"
    priorities_sql = <<~SQL.squish
      CASE #{submission_status_conditions(current_user)}
        WHEN 'not_graded' THEN #{priorities.fetch(:not_graded)}
        WHEN 'resubmitted' THEN #{priorities.fetch(:resubmitted)}
        WHEN 'not_submitted' THEN #{priorities.fetch(:not_submitted)}
        WHEN 'graded' THEN #{priorities.fetch(:graded)}
        WHEN 'not_gradeable' THEN #{priorities.fetch(:not_gradeable)}
        ELSE #{priorities.fetch(:other)}
      END
    SQL

    scope = status_base_scope(submission_scope).select("#{priorities_sql} AS #{column}")
    { scope:, column: }
  end

  def self.status_base_scope(submission_scope)
    submission_scope
      .joins(:assignment)
      .left_joins(:quiz_submission)
      .select("submissions.*")
  end

  def self.submission_status_conditions(current_user)
    <<~SQL.squish
      CASE
        WHEN submissions.workflow_state = 'unsubmitted'
          OR (
            submissions.submitted_at IS NULL
            AND submissions.grade IS NULL
            AND submissions.excused IS NOT TRUE
          ) THEN 'not_submitted'
        /* if the assignment is in the moderation phase and current user is not the moderator... */
        WHEN assignments.moderated_grading IS TRUE
          AND assignments.grades_published_at IS NULL
          AND assignments.grader_count IS NOT NULL
          AND assignments.final_grader_id IS DISTINCT FROM #{current_user.id}
          /* and we have reached max grader count... */
          AND (
            SELECT COUNT(*) FROM #{ModerationGrader.quoted_table_name} AS moderation_graders
            WHERE moderation_graders.assignment_id = submissions.assignment_id
              AND (moderation_graders.user_id IS DISTINCT FROM assignments.final_grader_id)
              AND moderation_graders.slot_taken = TRUE
          ) >= assignments.grader_count
          /* and the current user is not one of those graders... */
          AND NOT EXISTS (
            SELECT 1 FROM #{ModerationGrader.quoted_table_name} AS moderation_graders
            WHERE moderation_graders.assignment_id = submissions.assignment_id
              AND moderation_graders.user_id = #{current_user.id}
              AND moderation_graders.slot_taken = TRUE
          )
          /* then this submission is not gradeable by the current user */
          THEN 'not_gradeable'
        /* if the assignment is in the moderation phase and the current user is not the moderator... */
        WHEN assignments.moderated_grading IS TRUE
          AND assignments.grades_published_at IS NULL
          AND assignments.final_grader_id IS DISTINCT FROM #{current_user.id}
          /* and the current user has left a provisional grade for the student... */
          AND EXISTS (
            SELECT 1 FROM #{ModeratedGrading::ProvisionalGrade.quoted_table_name} AS provisional_grades
            WHERE provisional_grades.submission_id = submissions.id
              AND provisional_grades.scorer_id = #{current_user.id}
              AND provisional_grades.score IS NOT NULL
          /* then the submission is considered graded by the current user */
          ) THEN 'graded'
        /* if the assignment is in the moderation phase and the current user is the moderator... */
        WHEN assignments.moderated_grading IS TRUE
          AND assignments.grades_published_at IS NULL
          AND assignments.final_grader_id = #{current_user.id}
          /* and the current user has selected a provisional grade for the student... */
          AND EXISTS (
            SELECT 1 FROM #{ModeratedGrading::Selection.quoted_table_name} AS selections
            WHERE selections.assignment_id = submissions.assignment_id
              AND selections.student_id = submissions.user_id
              AND selections.selected_provisional_grade_id IS NOT NULL
          /* then the submission is considered graded by the current user */
          ) THEN 'graded'
        WHEN submissions.excused IS NOT TRUE
          AND (
            submissions.grade IS NULL
            OR submissions.workflow_state = 'pending_review'
          ) THEN 'not_graded'
        WHEN submissions.grade_matches_current_submission IS FALSE THEN 'resubmitted'
        ELSE 'graded'
      END
    SQL
  end
end
