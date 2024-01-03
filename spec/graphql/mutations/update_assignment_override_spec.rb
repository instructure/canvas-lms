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

require "spec_helper"
require_relative "../graphql_spec_helper"

describe Mutations::UpdateAssignment do
  before(:once) do
    @account = Account.create!
    @course = @account.courses.create!
    @course.require_assignment_group
    @course.save!
    @teacher = @course.enroll_teacher(User.create!, enrollment_state: "active").user
    @student = @course.enroll_student(User.create!, enrollment_state: "active").user
    @assignment_group = @course.assignment_groups.first
    group_category = GroupCategory.create(name: "Example Group Category", context: @course)
    @group = @course.groups.create!(group_category:)
    @group.users << @student
    @assignment_id = @assignment_group.assignments.create!(context: @course, name: "Example Assignment", group_category:).id
  end

  def execute_with_input(update_input, user_executing = @teacher)
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
            assignmentOverrides {
              nodes {
                _id
                title
                allDay
                dueAt
                lockAt
                unlockAt
                set {
                  ... on AdhocStudents {
                    students {_id}
                  }
                  ... on Section {
                    _id
                  }
                  ... on Group {
                    _id
                  }
                }
              }
            }
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
    context = { current_user: user_executing, request: ActionDispatch::TestRequest.create, session: {} }
    CanvasSchema.execute(mutation_command, context:)
  end

  #
  # different assert helpers to make sure we are testing each override is
  # completely correct every time. if we want to extend the checks for an
  # individual override, please put it in here to make sure that every way
  # that an override is mutated is checked.
  #

  def assert_adhoc_override(result_override, student_ids, assignment_id = @assignment_id)
    expect(result_override["set"]["students"].to_set { |s| s["_id"].to_i }).to eq student_ids.to_set
    override = Assignment.find(assignment_id).assignment_overrides.detect { |e| e.id.to_s == result_override["_id"] }
    expect(override).to_not be_nil
    override_set = override.set
    expect(override_set.length).to eq student_ids.length
    result_override["_id"]
  end

  def assert_section_override(result_override, section_id, assignment_id = @assignment_id)
    expect(result_override["set"]["_id"]).to eq section_id.to_s
    override = Assignment.find(assignment_id).assignment_overrides.detect { |e| e.id.to_s == result_override["_id"] }
    expect(override).to_not be_nil
    override_set = override.set
    expect(override_set.class).to eq CourseSection
    expect(override_set.id).to eq section_id
    result_override["_id"]
  end

  def assert_group_override(result_override, group_id, assignment_id = @assignment_id)
    expect(result_override["set"]["_id"]).to eq group_id.to_s
    override = Assignment.find(assignment_id).assignment_overrides.detect { |e| e.id.to_s == result_override["_id"] }
    expect(override).to_not be_nil
    override_set = override.set
    expect(override_set.class).to eq Group
    expect(override_set.id).to eq group_id
    result_override["_id"]
  end

  def assert_no_errors_and_get_overrides(result)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateAssignment", "errors")).to be_nil
    expect(result.dig("data", "updateAssignment", "assignment", "_id")).to eq @assignment_id.to_s
    result.dig("data", "updateAssignment", "assignment", "assignmentOverrides", "nodes")
  end

  #
  # test start here
  #

  it "can create adhoc override" do
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      assignmentOverrides: [
        {
          studentIds: ["#{@student.id}"]
        }
      ]
    GQL
    result_overrides = assert_no_errors_and_get_overrides(result)
    expect(result_overrides.length).to eq 1
    expect(Assignment.find(@assignment_id).active_assignment_overrides.length).to eq 1
    assert_adhoc_override(result_overrides[0], [@student.id])
  end

  it "can create section override" do
    section = @course.course_sections.create!
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      assignmentOverrides: [
        {
          courseSectionId: "#{section.id}"
        }
      ]
    GQL
    result_overrides = assert_no_errors_and_get_overrides(result)
    expect(result_overrides.length).to eq 1
    expect(Assignment.find(@assignment_id).active_assignment_overrides.length).to eq 1
    assert_section_override(result_overrides[0], section.id)
  end

  it "can create group override" do
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      assignmentOverrides: [
        {
          groupId: "#{@group.id}"
        }
      ]
    GQL
    result_overrides = assert_no_errors_and_get_overrides(result)
    expect(result_overrides.length).to eq 1
    expect(Assignment.find(@assignment_id).active_assignment_overrides.length).to eq 1
    assert_group_override(result_overrides[0], @group.id)
  end

  it "errors on no override info" do
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      assignmentOverrides: [
        {
        }
      ]
    GQL
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateAssignment", "errors", 0, "message")).to eq "one of student_ids, group_id, or course_section_id is required"
  end

  it "can create multiple overrides then remove one" do
    section = @course.course_sections.create!
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      assignmentOverrides: [
        {
          studentIds: ["#{@student.id}"]
        }
        {
          courseSectionId: "#{section.id}"
        }
        {
          groupId: "#{@group.id}"
        }
      ]
    GQL
    result_overrides = assert_no_errors_and_get_overrides(result)
    expect(result_overrides.length).to eq 3
    expect(Assignment.find(@assignment_id).active_assignment_overrides.length).to eq 3
    group_override = result_overrides.find { |ro| ro["title"] == @group.name }
    group_override_id = assert_group_override(group_override, @group.id)
    section_override = result_overrides.find { |ro| ro["title"] == section.name }
    assert_section_override(section_override, section.id)
    adhoc_override = result_overrides.find { |ro| ro["title"] == "1 student" }
    adhoc_override_id = assert_adhoc_override(adhoc_override, [@student.id])

    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      assignmentOverrides: [
        {
          id: "#{adhoc_override_id}"
          studentIds: ["#{@student.id}"]
        }
        {
          id: "#{group_override_id}"
          groupId: "#{@group.id}"
        }
      ]
    GQL
    result_overrides = assert_no_errors_and_get_overrides(result)
    expect(result_overrides.length).to eq 2
    expect(Assignment.find(@assignment_id).active_assignment_overrides.length).to eq 2
    expect(result_overrides[0]["_id"]).to eq group_override_id
    expect(result_overrides[1]["_id"]).to eq adhoc_override_id
    assert_group_override(result_overrides[0], @group.id)
    assert_adhoc_override(result_overrides[1], [@student.id])
  end

  it "can update an adhoc override students" do
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      assignmentOverrides: [
        {
          studentIds: ["#{@student.id}"]
        }
      ]
    GQL
    result_overrides = assert_no_errors_and_get_overrides(result)
    expect(result_overrides.length).to eq 1
    expect(Assignment.find(@assignment_id).active_assignment_overrides.length).to eq 1
    override_id = assert_adhoc_override(result_overrides[0], [@student.id])

    @new_student_1 = @course.enroll_student(User.create!, enrollment_state: "active").user
    @new_student_2 = @course.enroll_student(User.create!, enrollment_state: "active").user
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      assignmentOverrides: [
        {
          id: "#{override_id}"
          studentIds: ["#{@student.id}", "#{@new_student_1.id}", "#{@new_student_2.id}"]
        }
      ]
    GQL
    result_overrides = assert_no_errors_and_get_overrides(result)
    expect(result_overrides.length).to eq 1
    expect(result_overrides[0]["_id"]).to eq override_id
    expect(Assignment.find(@assignment_id).active_assignment_overrides.length).to eq 1
    expect(Assignment.find(@assignment_id).active_assignment_overrides[0].id).to eq override_id.to_i
    assert_adhoc_override(result_overrides[0], [@student.id, @new_student_1.id, @new_student_2.id])

    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      assignmentOverrides: [
        {
          id: "#{override_id}"
          studentIds: ["#{@student.id}", "#{@new_student_2.id}"]
        }
      ]
    GQL
    result_overrides = assert_no_errors_and_get_overrides(result)
    expect(result_overrides.length).to eq 1
    expect(result_overrides[0]["_id"]).to eq override_id
    expect(Assignment.find(@assignment_id).active_assignment_overrides.length).to eq 1
    expect(Assignment.find(@assignment_id).active_assignment_overrides[0].id).to eq override_id.to_i
    assert_adhoc_override(result_overrides[0], [@student.id, @new_student_2.id])
  end

  def setup_field_update_test(field_testing, field_graphql)
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      assignmentOverrides: [
        {
          studentIds: ["#{@student.id}"]
        }
      ]
    GQL
    result_overrides = assert_no_errors_and_get_overrides(result)
    override_id = assert_adhoc_override(result_overrides[0], [@student.id])
    override_check = Assignment.find(@assignment_id).active_assignment_overrides[0]
    expect(override_check.send(field_testing)).to be_nil

    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      assignmentOverrides: [
        {
          id: "#{override_id}"
          #{field_graphql}: "2018-01-01T01:00:00Z"
        }
      ]
    GQL
    result_overrides = assert_no_errors_and_get_overrides(result)
    assert_adhoc_override(result_overrides[0], [@student.id])
    override_check = Assignment.find(@assignment_id).active_assignment_overrides[0]
    expect(override_check.send(field_testing)).to eq "2018-01-01T01:00:00Z"

    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      assignmentOverrides: [
        {
          id: "#{override_id}"
        }
      ]
    GQL
    result_overrides = assert_no_errors_and_get_overrides(result)
    assert_adhoc_override(result_overrides[0], [@student.id])
    override_check = Assignment.find(@assignment_id).active_assignment_overrides[0]
    expect(override_check.send(field_testing)).to be_nil
  end

  it "can update override dueAt" do
    setup_field_update_test(:due_at, "dueAt")
  end

  it "can update override lockAt" do
    setup_field_update_test(:lock_at, "lockAt")
  end

  it "can update override unlockAt" do
    setup_field_update_test(:unlock_at, "unlockAt")
  end

  it "error shows when override set overlaps" do
    section = @course.course_sections.create!
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      assignmentOverrides: [
        {
          courseSectionId: "#{section.id}"
          unlockAt: "2018-01-01T01:00:00Z"
        }
        {
          courseSectionId: "#{section.id}"
          unlockAt: "2018-01-02T01:00:00Z"
        }
      ]
    GQL
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateAssignment", "errors", 0, "message")).to eq "Validation failed: Set has already been taken"
  end

  it "invalid dates cause validation errors" do
    section1 = @course.course_sections.create!
    section2 = @course.course_sections.create!
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      assignmentOverrides: [
        {
          courseSectionId: "#{section1.id}"
          dueAt: "2019-02-28T17:01:00Z-05:00"
        }
        {
          courseSectionId: "#{section2.id}"
          dueAt: "2018:02-28T17:02:00Z-05:00"
        }
      ]
    GQL
    expect(result.dig("errors", 1, "extensions", "code")).to eq "argumentLiteralsIncompatible"
  end
end
