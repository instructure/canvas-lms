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

class Mutations::UpdateAssignment < Mutations::BaseMutation
  include Api::V1::Assignment

  graphql_name "UpdateAssignment"

  # input arguments
  argument :id, ID, required: true
  argument :name, String, required: false
  argument :state, Types::AssignmentType::AssignmentStateType, required: false
  argument :due_at, Types::DateTimeType, required: false
  argument :description, String, required: false

  # the return data if the update is successful
  field :assignment, Types::AssignmentType, null: true

  def resolve(input:)
    assignment_id = GraphQLHelpers.parse_relay_or_legacy_id(input[:id], "Assignment")

    # make this a field so callbacks can reference
    begin
      @working_assignment = Assignment.find(assignment_id)
    rescue ActiveRecord::RecordNotFound
      raise GraphQL::ExecutionError, "assignment not found: #{assignment_id}"
    end

    # check permissions asap
    raise GraphQL::ExecutionError, "insufficient permission" unless @working_assignment.grants_right? current_user, :update

    # to use the update_api_assignment method, we have to modify some of the
    # input. first, update_api_assignment doesnt expect a :state key. instead,
    # it expects a :published key of boolean type.
    # also, if we are required to transition to restored or destroyed, then we
    # need to handle those as well.
    input_hash = input.to_h
    other_update_on_assignment = false
    if input_hash.has_key? :state
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

    # make sure to do other required updates
    self.send(other_update_on_assignment) if other_update_on_assignment

    # normal update now
    @working_assignment.content_being_saved_by(current_user)
    @working_assignment.updating_user = current_user
    result = update_api_assignment(@working_assignment, ActionController::Parameters.new(input_hash), current_user, @working_assignment.context)

    # return the result
    if [:ok, :created].include? result
      { assignment: @working_assignment }
    else
      { errors: @working_assignment.errors.entries }
    end
  end

  def ensure_destroyed
    # check for permissions no matter what
    raise GraphQL::ExecutionError, "insufficient permission" unless @working_assignment.grants_right? current_user, :delete

    # if we are already destroyed, then dont do anything
    return if @working_assignment.workflow_state == "deleted"

    # actually destroy now.
    DueDateCacher.with_executing_user(@current_user) do
      @working_assignment.destroy
    end
  end

  def ensure_restored
    raise GraphQL::ExecutionError, "insufficient permission" unless @working_assignment.grants_right? current_user, :delete
    # if we are already not destroyed, then dont do anything
    return if @working_assignment.workflow_state != "deleted"

    @working_assignment.restore
  end

  #
  # the methods below here are required callbacks from the update_api_assignment method.
  #

  def grading_periods?
    @working_assignment.try(:grading_periods?)
  end

  def strong_anything
    ArbitraryStrongishParams::ANYTHING
  end

  def value_to_boolean(value)
    Canvas::Plugin.value_to_boolean(value)
  end

  def process_incoming_html_content(html)
    Api::Html::Content.process_incoming(html)
  end
end
