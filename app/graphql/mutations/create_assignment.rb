# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

class Mutations::CreateAssignment < Mutations::AssignmentBase
  graphql_name "CreateAssignment"

  argument :course_id, ID, required: true
  argument :name, String, required: true
  # most arguments inherited from AssignmentBase

  def resolve(input:, submittable: nil)
    course_id = GraphQLHelpers.parse_relay_or_legacy_id(input[:course_id], "Course")

    @course = Course.find_by(id: course_id)
    @working_assignment = @course.assignments.build if @course

    raise GraphQL::ExecutionError, "invalid course: #{course_id}" unless @working_assignment&.grants_right? current_user, :create

    # initialize published argument
    @working_assignment.workflow_state = "unpublished"
    input_hash = input.to_h
    if input_hash.key? :state
      asked_state = input_hash.delete :state
      case asked_state
      when "unpublished"
        input_hash[:published] = false
      when "published"
        input_hash[:published] = true
      else
        raise "unable to handle state change: #{asked_state}"
      end
    end

    if submittable
      submittable.assignment = @working_assignment
    end

    api_proxy = ApiProxy.new(context[:request], @working_assignment, context[:session], current_user)

    validate_for_checkpoints(input_hash)

    # modifies input_hash
    prepare_input_params!(input_hash, api_proxy)

    module_ids = prepare_module_ids!(input_hash)

    @working_assignment.content_being_saved_by(current_user)
    @working_assignment.updating_user = current_user

    result = api_proxy.create_api_assignment(@working_assignment, ActionController::Parameters.new(input_hash), current_user, @course)
    if [:ok, :created].include? result
      # ensure the assignment is part of all required modules (this must be done after the assignment is created)
      ensure_modules(module_ids) if module_ids
      { assignment: @working_assignment }
    else
      { errors: @working_assignment.errors.entries }
    end
  end
end
