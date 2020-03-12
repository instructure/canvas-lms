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

class Mutations::UpdateAssignment < Mutations::AssignmentBase
  graphql_name "UpdateAssignment"

  argument :id, ID, required: true
  argument :name, String, required: false
  # most arguments inherited from AssignmentBase

  def resolve(input:)
    assignment_id = GraphQLHelpers.parse_relay_or_legacy_id(input[:id], "Assignment")

    begin
      @working_assignment = Assignment.find(assignment_id)
    rescue ActiveRecord::RecordNotFound
      raise GraphQL::ExecutionError, "assignment not found: #{assignment_id}"
    end

    # check permissions asap
    raise GraphQL::ExecutionError, "insufficient permission" unless @working_assignment.grants_right? current_user, :update

    update_proxy = ApiProxy.new(context[:request], @working_assignment, context[:session], current_user)

    # to use the update_api_assignment method, we have to modify some of the
    # input. first, update_api_assignment doesnt expect a :state key. instead,
    # it expects a :published key of boolean type.
    # also, if we are required to transition to restored or destroyed, then we
    # need to handle those as well.
    input_hash = input.to_h
    other_update_on_assignment = false
    if input_hash.key? :state
      asked_state = input_hash.delete :state
      case asked_state
      when "unpublished"
        input_hash[:published] = false
        other_update_on_assignment = :ensure_restored
      when "published"
        input_hash[:published] = true
        other_update_on_assignment = :ensure_restored
      when "deleted"
        other_update_on_assignment = :ensure_destroyed
      else
        raise "unable to handle state change: #{asked_state}"
      end
    end

    # modifies input_hash
    prepare_input_params!(input_hash, update_proxy)

    # This is here because update_api_assignment no longer respects `muted` as
    # a param. It is also being deprecated from the AssignmentBase mutation.
    muted = input_hash.delete(:muted)
    unless muted.nil?
      if muted != @working_assignment.muted?
        @working_assignment.update!(muted: muted)
      end
    end

    module_ids = prepare_module_ids!(input_hash)

    # make sure to do other required updates
    self.send(other_update_on_assignment) if other_update_on_assignment

    # ensure the assignment is part of all required modules
    ensure_modules(module_ids) if module_ids

    # normal update now
    @working_assignment.content_being_saved_by(current_user)
    @working_assignment.updating_user = current_user
    result = update_proxy.update_api_assignment(@working_assignment, ActionController::Parameters.new(input_hash), current_user, @working_assignment.context)

    # return the result
    if [:ok, :created].include? result
      { assignment: @working_assignment }
    else
      { errors: @working_assignment.errors.entries }
    end
  end
end
