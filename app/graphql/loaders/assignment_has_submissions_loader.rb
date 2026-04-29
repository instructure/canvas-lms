# frozen_string_literal: true

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

class Loaders::AssignmentHasSubmissionsLoader < GraphQL::Batch::Loader
  def perform(assignment_ids)
    # Check which assignments have student submissions
    assignments_with_submissions = Submission
                                   .active
                                   .having_submission
                                   .where(assignment_id: assignment_ids)
                                   .where.not(user_id: nil)
                                   .distinct
                                   .pluck(:assignment_id)
                                   .to_set

    assignment_ids.each do |assignment_id|
      has_submissions = assignments_with_submissions.include?(assignment_id)
      fulfill(assignment_id, has_submissions)
    end
  end
end
