# frozen_string_literal: true

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

class Mutations::SetAssignmentPostPolicy < Mutations::BaseMutation
  graphql_name "SetAssignmentPostPolicy"

  argument :assignment_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Assignment")
  argument :post_manually, Boolean, required: true

  field :post_policy, Types::PostPolicyType, null: true

  def resolve(input:)
    begin
      assignment = Assignment.find(input[:assignment_id])
      course = assignment.context
    rescue ActiveRecord::RecordNotFound
      raise GraphQL::ExecutionError, "An assignment with that id does not exist"
    end

    verify_authorized_action!(course, :manage_grades)

    if input[:post_manually] == false
      raise GraphQL::ExecutionError, I18n.t("Anonymous assignments must be manually posted") if assignment.anonymous_grading?

      if assignment.moderated_grading? && !assignment.grades_published?
        raise GraphQL::ExecutionError, I18n.t("Moderated assignments must be manually posted until grades are released")
      end
    end

    policy = PostPolicy.find_or_create_by(course:, assignment:)
    policy.update!(post_manually: input[:post_manually])

    { post_policy: policy }
  end

  def self.post_policy_log_entry(post_policy, _context)
    post_policy.assignment
  end
end
