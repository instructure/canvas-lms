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

  def self.add_needs_grading_column(submission_scope)
    column = "db_needs_grading"
    scope = submission_scope.select(
      "submissions.*",
      "#{Submission.needs_grading_conditions} AS #{column}"
    )

    { scope:, column: }
  end

  def self.add_submission_status_column(submission_scope)
    column = "db_submission_status"
    scope = status_base_scope(submission_scope)
            .select("#{Submission.submission_status_conditions} AS #{column}")

    { scope:, column: }
  end

  def self.add_submission_status_priority_column(submission_scope, priorities)
    column = "db_submission_status_priority"
    priorities_sql = <<~SQL.squish
      CASE #{Submission.submission_status_conditions}
        WHEN 'not_graded' THEN #{priorities.fetch(:not_graded)}
        WHEN 'resubmitted' THEN #{priorities.fetch(:resubmitted)}
        WHEN 'not_submitted' THEN #{priorities.fetch(:not_submitted)}
        WHEN 'graded' THEN #{priorities.fetch(:graded)}
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
end
