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

require "spec_helper"
require "helpers/graphql_type_tester"

describe Mutations::UpdateAssignment do
  before do
    @account = Account.create!
    @course = @account.courses.create!
    @teacher = @course.enroll_teacher(User.create!, enrollment_state: 'active').user
    @student = @course.enroll_student(User.create!, enrollment_state: 'active').user
    @assignment_id = @course.assignments.create!(title: "Example Assignment").id
  end

  def execute_with_input(update_input, user_executing=@teacher)
    mutation_command = <<~GQL
      mutation {
        updateAssignment(input: {
          #{update_input}
        }) {
          assignment {
            _id
            name
            state
            description
            dueAt
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
    context = {current_user: user_executing, request: ActionDispatch::TestRequest.create}
    return CanvasSchema.execute(mutation_command, context: context)
  end

  it "can do basic update on name" do
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      name: "some other assignment title"
    GQL
    expect(result.dig('errors')).to be_nil
    expect(result.dig('data', 'updateAssignment', 'errors')).to be_nil
    expect(result.dig('data', 'updateAssignment', 'assignment', '_id')).to eq @assignment_id.to_s
    expect(result.dig('data', 'updateAssignment', 'assignment', 'name')).to eq "some other assignment title"
    expect(Assignment.find(@assignment_id).name).to eq "some other assignment title"
  end

  it "can update description" do
    expect(Assignment.find(@assignment_id).description).to be_nil
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      description: "this is a description and stuffs"
    GQL
    expect(result.dig('errors')).to be_nil
    expect(result.dig('data', 'updateAssignment', 'errors')).to be_nil
    expect(result.dig('data', 'updateAssignment', 'assignment', 'description')).to eq "this is a description and stuffs"
    expect(Assignment.find(@assignment_id).description).to eq "this is a description and stuffs"
  end

  it "can update state" do
    expect(Assignment.find(@assignment_id).workflow_state).to eq "published"
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      state: unpublished
    GQL
    expect(result.dig('errors')).to be_nil
    expect(result.dig('data', 'updateAssignment', 'errors')).to be_nil
    expect(result.dig('data', 'updateAssignment', 'assignment', 'state')).to eq "unpublished"
    expect(Assignment.find(@assignment_id).workflow_state).to eq "unpublished"

    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      state: published
    GQL
    expect(result.dig('errors')).to be_nil
    expect(result.dig('data', 'updateAssignment', 'errors')).to be_nil
    expect(result.dig('data', 'updateAssignment', 'assignment', 'state')).to eq "published"
    expect(Assignment.find(@assignment_id).workflow_state).to eq "published"
  end

  it "can update dueAt" do
    expect(Assignment.find(@assignment_id).due_at).to be_nil
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      dueAt: "2018-01-01T01:00:00Z"
    GQL
    expect(result.dig('errors')).to be_nil
    expect(result.dig('data', 'updateAssignment', 'errors')).to be_nil
    expect(result.dig('data', 'updateAssignment', 'assignment', 'dueAt')).to eq "2018-01-01T01:00:00Z"
    expect(Assignment.find(@assignment_id).due_at).to eq "2018-01-01T01:00:00Z"
  end

  it "can delete and then restore" do
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      state: deleted
      name: "Example Assignment (deleted)"
    GQL
    expect(result.dig('errors')).to be_nil
    expect(result.dig('data', 'updateAssignment', 'errors')).to be_nil
    expect(result.dig('data', 'updateAssignment', 'assignment', 'state')).to eq "deleted"
    expect(result.dig('data', 'updateAssignment', 'assignment', 'name')).to eq "Example Assignment (deleted)"
    expect(Assignment.find(@assignment_id).name).to eq "Example Assignment (deleted)"
    expect(Assignment.find(@assignment_id).workflow_state).to eq "deleted"

    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      state: published
      name: "not deleted anymore!"
    GQL
    expect(result.dig('errors')).to be_nil
    expect(result.dig('data', 'updateAssignment', 'errors')).to be_nil
    expect(result.dig('data', 'updateAssignment', 'assignment', 'state')).to eq "published"
    expect(result.dig('data', 'updateAssignment', 'assignment', 'name')).to eq "not deleted anymore!"
    expect(Assignment.find(@assignment_id).name).to eq "not deleted anymore!"
    expect(Assignment.find(@assignment_id).workflow_state).to eq "published"
  end

  it "can update to same state without error" do
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      state: deleted
    GQL
    expect(result.dig('errors')).to be_nil
    expect(result.dig('data', 'updateAssignment', 'errors')).to be_nil
    expect(result.dig('data', 'updateAssignment', 'assignment', 'state')).to eq "deleted"
    expect(Assignment.find(@assignment_id).workflow_state).to eq "deleted"

    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      state: deleted
    GQL
    expect(result.dig('errors')).to be_nil
    expect(result.dig('data', 'updateAssignment', 'errors')).to be_nil
    expect(result.dig('data', 'updateAssignment', 'assignment', 'state')).to eq "deleted"
    expect(Assignment.find(@assignment_id).workflow_state).to eq "deleted"

    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      state: published
    GQL
    expect(result.dig('errors')).to be_nil
    expect(result.dig('data', 'updateAssignment', 'errors')).to be_nil
    expect(result.dig('data', 'updateAssignment', 'assignment', 'state')).to eq "published"
    expect(Assignment.find(@assignment_id).workflow_state).to eq "published"

    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      state: published
    GQL
    expect(result.dig('errors')).to be_nil
    expect(result.dig('data', 'updateAssignment', 'errors')).to be_nil
    expect(result.dig('data', 'updateAssignment', 'assignment', 'state')).to eq "published"
    expect(Assignment.find(@assignment_id).workflow_state).to eq "published"
  end

  it "can do multiple updates" do
    # this shows two things:
    # 1 - you can do multiple mutations.. even of the same type
    # 2 - mutations happen in the order they are placed, one at a time
    mutation_command = <<~GQL
      mutation {
        changeName: updateAssignment(input: {
          id: "#{@assignment_id}"
          name: "Example Assignment (deleted)"
        }) {
          assignment {
            _id
            name
            state
          }
          errors {
            attribute
            message
          }
        }
        delete: updateAssignment(input: {
          id: "#{@assignment_id}"
          state: deleted
        }) {
          assignment {
            _id
            name
            state
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
    context = {current_user: @teacher, request: ActionDispatch::TestRequest.create}
    result = CanvasSchema.execute(mutation_command, context: context)
    expect(result.dig('errors')).to be_nil
    expect(result.dig('data', 'changeName', 'errors')).to be_nil
    expect(result.dig('data', 'changeName', 'assignment', 'name')).to eq "Example Assignment (deleted)"
    expect(result.dig('data', 'changeName', 'assignment', 'state')).to eq "published"
    expect(result.dig('data', 'delete', 'errors')).to be_nil
    expect(result.dig('data', 'delete', 'assignment', 'name')).to eq "Example Assignment (deleted)"
    expect(result.dig('data', 'delete', 'assignment', 'state')).to eq "deleted"
  end

  it "can handle not found gracefully" do
    result = execute_with_input <<~GQL
      id: "1234"
      state: deleted
    GQL
    errors = result.dig('errors')
    expect(errors).to_not be_nil
    expect(errors[0]["message"]).to eq "assignment not found: 1234"
  end

  it "can handle bad input gracefully" do
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      state: "deleted"
    GQL
    errors = result.dig('errors')
    expect(errors).to_not be_nil
    expect(errors.length).to be 2
    # these are not derived or created by our code. so if they change, just replace with the new string
    expect(errors[0]["message"]).to eq "Argument 'input' on Field 'updateAssignment' has an invalid value. Expected type 'UpdateAssignmentInput!'."
    expect(errors[1]["message"]).to eq "Argument 'state' on InputObject 'UpdateAssignmentInput' has an invalid value. Expected type 'AssignmentState'."
  end

  # we cannot force this naturally yet, so lets wait until we have on of the fields that we can.
  # it "validation errors return correctly" do
  #   result = execute_with_input <<~GQL
  #     id: "#{@assignment_id}"
  #     dueAt: "2018-01-01T01:00:00Za"
  #   GQL
  #   expect(result.dig('errors')).to be_nil
  #   expect(result.dig('data', 'updateAssignment', 'assignment')).to be_nil
  #   expect(result.dig('data', 'updateAssignment', 'errors')).to_not be_nil
  # end

  it "cannot update without correct permissions" do
    # bad student! dont delete the assignment
    result = execute_with_input(<<~GQL, user_executing=@student)
      id: "#{@assignment_id}"
      state: deleted
    GQL
    errors = result.dig('errors')
    expect(errors).to_not be_nil
    expect(errors.length).to be 1
    expect(errors[0]["message"]).to eq "insufficient permission"
  end

end
