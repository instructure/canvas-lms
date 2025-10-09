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

class Checkpoints::SubAssignmentSubmissionSerializer
  class MissingSubAssignmentSubmissionError < StandardError
    def initialize(message = "Submission is missing for SubAssignment")
      super
    end
  end

  def self.serialize(assignment:, user_id:)
    return { has_active_submissions: false, submissions: [] } unless assignment.has_sub_assignments

    user_has_active_sub_submissions = false
    submissions = assignment.sub_assignments&.filter_map do |sub_assignment|
      result = find_single_sub_assignment_submission(sub_assignment, user_id)
      user_has_active_sub_submissions = true if result.present?
      result
    end

    {
      has_active_submissions: user_has_active_sub_submissions,
      submissions: submissions || []
    }
  end

  def self.find_single_sub_assignment_submission(sub_assignment, user_id)
    sub_assignment_submission = sub_assignment.submissions.find_by(user_id:)

    if sub_assignment_submission.present?
      sub_assignment_submission
    else
      any_submission_ever = Submission.unscoped.find_by(assignment_id: sub_assignment.id, user_id:)

      if any_submission_ever.nil?
        raise MissingSubAssignmentSubmissionError, "Submission is missing for SubAssignment #{sub_assignment.id} and user #{user_id}"
      else
        nil
      end
    end
  end
end
