#
# Copyright (C) 2018 - present Instructure, Inc.
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

class Mutations::HideAssignmentGrades < Mutations::BaseMutation
  graphql_name "HideAssignmentGrades"

  argument :assignment_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Assignment")

  field :assignment, Types::AssignmentType, null: true
  field :progress, Types::ProgressType, null: true

  def resolve(input:)
    begin
      assignment = Assignment.find(input[:assignment_id])
      course = assignment.context
    rescue ActiveRecord::RecordNotFound
      raise GraphQL::ExecutionError, "not found"
    end

    verify_authorized_action!(assignment, :grade)
    raise GraphQL::ExecutionError, "Post Policies feature not enabled" unless course.feature_enabled?(:post_policies)

    unless assignment.grades_published?
      raise GraphQL::ExecutionError, "Assignments under moderation cannot be hidden before grades are published"
    end

    submission_ids = assignment.submissions.active.pluck(:id)
    progress = course.progresses.new(tag: "hide_assignment_grades")

    if progress.save
      progress.process_job(assignment, :hide_submissions, {preserve_method_args: true}, submission_ids: submission_ids)
      return {assignment: assignment, progress: progress}
    else
      raise GraphQL::ExecutionError, "Error hiding assignment grades"
    end
  end
end
