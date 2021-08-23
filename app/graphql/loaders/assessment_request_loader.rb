# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

class Loaders::AssessmentRequestLoader < GraphQL::Batch::Loader
  def initialize(current_user:)
    @current_user = current_user
  end

  def perform(assignments)
    assignments.each do |assignment|
      reviews = @current_user.assigned_submission_assessments.shard(assignment.shard).for_assignment(assignment.id)
      valid_student_ids = assignment.course.participating_students.where(id: reviews.select('user_id'))
      fulfill(assignment, reviews.where(user_id: valid_student_ids))
    end
  end
end
