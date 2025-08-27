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

class Mutations::AutoGradeSubmission < Mutations::BaseMutation
  argument :submission_id, ID, required: true

  field :error, String, null: true
  field :progress, Types::ProgressType, null: true

  def resolve(input:)
    submission_id = GraphQLHelpers.parse_relay_or_legacy_id(input[:submission_id], "Submission")
    submission = Submission.find(submission_id)

    errors = []
    append_issue_message(errors, GraphQLHelpers::AutoGradeEligibilityHelper.validate_assignment(assignment: submission.assignment))
    append_issue_message(errors, GraphQLHelpers::AutoGradeEligibilityHelper.validate_submission(submission:))

    if errors.any?
      raise GraphQL::ExecutionError, "Auto-grading failed due to the following issue(s): #{errors.join(", ")}"
    end

    course = submission.assignment&.course
    raise "Course not found" unless course

    unless course.feature_enabled?(:project_lhotse)
      raise GraphQL::ExecutionError, I18n.t("Project Lhotse is not enabled for this course.")
    end

    verify_authorized_action!(course, :manage_grades)

    service = AutoGradeOrchestrationService.new(course:, current_user:)
    progress = service.auto_grade_in_background(submission:)

    { progress: }
  rescue GraphQL::ExecutionError => e
    Rails.logger.error("[AutoGradeSubmission GraphQL ExecutionError] #{e.message}")
    raise e
  rescue => e
    Rails.logger.error("[AutoGradeSubmission ERROR] #{e.message}")
    raise GraphQL::ExecutionError, I18n.t("An unexpected error occurred while grading.")
  end

  def append_issue_message(errors, issue)
    errors << issue[:message] if issue && issue[:level] == "error"
  end
end
