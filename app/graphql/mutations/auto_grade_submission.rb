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
  field :progress_id, ID, null: true

  def resolve(input:)
    submission_id = GraphQLHelpers.parse_relay_or_legacy_id(input[:submission_id], "Submission")
    submission = Submission.find(submission_id)

    raise "Submission not found" unless submission

    course = submission.assignment&.course
    raise "Course not found" unless course

    unless course.feature_enabled?(:project_lhotse)
      return { error: "Project Lhotse is not enabled for this course" }
    end

    verify_authorized_action!(course, :manage_grades)

    progress_info = course.auto_grade_submission_in_background(submission)

    { progress_id: progress_info[:progress_id] }
  rescue => e
    Rails.logger.error("[AutoGradeSubmission ERROR] #{e.message}")
    { error: "An unexpected error occurred while grading." }
  end
end
