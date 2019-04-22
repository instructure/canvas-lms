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

class Mutations::SetCoursePostPolicy < Mutations::BaseMutation
  graphql_name "SetCoursePostPolicy"

  argument :course_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Course")
  argument :override_assignment_post_policies, Boolean,
    <<~DOC,
      If true, the course post policy will override and delete any currently
      existing assignment post policies.
    DOC
    required: false
  argument :post_manually, Boolean, required: true

  field :post_policy, Types::PostPolicyType, null: true

  def resolve(input:)
    begin
      course = Course.find(input[:course_id])
    rescue ActiveRecord::RecordNotFound
      raise GraphQL::ExecutionError, "A course with that id does not exist"
    end

    verify_authorized_action!(course, :manage_grades)

    policy = PostPolicy.find_or_create_by(course: course, assignment_id: nil)
    policy.update!(post_manually: input[:post_manually])

    if input[:override_assignment_post_policies]
      course.assignment_post_policies.destroy_all
    end

    {post_policy: policy}
  end
end
