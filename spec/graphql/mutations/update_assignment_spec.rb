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
  before do
    @account = Account.create!
    @course = @account.courses.create!
    @teacher = @course.enroll_teacher(User.create!, enrollment_state: "active").user
    @student = @course.enroll_student(User.create!, enrollment_state: "active").user
    @assignment_id = @course.assignments.create!(title: "Example Assignment").id
    @course.enable_feature!(:anonymous_marking)
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
            lockAt
            unlockAt
            position
            pointsPossible
            gradingType
            allowedExtensions
            assignmentGroup { _id }
            groupSet { _id }
            allowedAttempts
            onlyVisibleToOverrides
            submissionTypes
            gradeGroupStudentsIndividually
            anonymousInstructorAnnotations
            omitFromFinalGrade
            postToSis
            anonymousGrading
            assignmentOverrides {
              nodes {
                id
              }
            }
            moderatedGrading {
              enabled
              graderCount
              graderCommentsVisibleToGraders
              graderNamesVisibleToFinalGrader
              gradersAnonymousToGraders
              finalGrader { _id }
            }
            peerReviews {
              enabled
              count
              dueAt
              intraReviews
              anonymousReviews
              automaticReviews
            }
            modules {
              _id
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

  def create_module_and_add_assignment(name)
    course_module1 = @course.context_modules.create!(name:)
    course_module1.add_item(id: @assignment_id, type: "assignment")
    course_module1
  end

  def get_assignment_module_ids
    assignment = Assignment.find(@assignment_id)
    return [] if assignment.context_module_tag_ids.empty?

    ContentTag.find(assignment.context_module_tag_ids).map(&:context_module_id).sort
  end

  def run_single_value_update_test(graphql_name, assignment_name, initial_value, update_value, graphql_result, assignment_result = graphql_result)
    expect(Assignment.find(@assignment_id).send(assignment_name)).to eq initial_value
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      #{graphql_name}: #{update_value}
    GQL
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateAssignment", "errors")).to be_nil
    expect(result.dig("data", "updateAssignment", "assignment", graphql_name)).to eq graphql_result
    expect(Assignment.find(@assignment_id).send(assignment_name)).to eq assignment_result
  end

  [
    ["name", :name, "Example Assignment", '"some other assignment title"', "some other assignment title"],
    ["description", :description, nil, '"this is a description"', "this is a description"],
    ["dueAt", :due_at, nil, '"2018-01-01T01:00:00Z"', "2018-01-01T01:00:00Z"],
    ["lockAt", :lock_at, nil, '"2018-01-01T01:00:00Z"', "2018-01-01T01:00:00Z"],
    ["unlockAt", :unlock_at, nil, '"2018-01-01T01:00:00Z"', "2018-01-01T01:00:00Z"],
    ["position", :position, 1, 2, 2],
    ["pointsPossible", :points_possible, nil, 100, 100],
    ["gradingType", :grading_type, "points", "not_graded", "not_graded"],
    ["allowedExtensions", :allowed_extensions, [], '[ "docs", "blah" ]', ["docs", "blah"]],
    ["allowedAttempts", :allowed_attempts, nil, 10, 10],
    ["onlyVisibleToOverrides", :only_visible_to_overrides, false, true, true],
    ["submissionTypes", :submission_types, "none", "[ discussion_topic, not_graded ]", ["discussion_topic", "not_graded"], "discussion_topic,not_graded"],
    ["gradeGroupStudentsIndividually", :grade_group_students_individually, false, true, true],
    ["omitFromFinalGrade", :omit_from_final_grade, false, true, true],
    ["anonymousInstructorAnnotations", :anonymous_instructor_annotations, false, true, true],
    ["postToSis", :post_to_sis, false, true, true],
    ["anonymousGrading", :anonymous_grading, false, true, true],
  ].each do |inputs|
    it "can update #{inputs[0]}" do
      run_single_value_update_test(*inputs)
    end
  end

  it "can update moderatedGrading" do
    assignment = Assignment.find(@assignment_id)
    expect(assignment.moderated_grading).to be false
    expect(assignment.grader_count).to eq 0
    expect(assignment.grader_comments_visible_to_graders).to be true
    expect(assignment.grader_names_visible_to_final_grader).to be true
    expect(assignment.graders_anonymous_to_graders).to be false
    expect(assignment.final_grader_id).to be_nil
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      moderatedGrading: {
        enabled: true
        graderCount: 1
        graderCommentsVisibleToGraders: false
        graderNamesVisibleToFinalGrader: false
        gradersAnonymousToGraders: true
        finalGraderId: "#{@teacher.id}"
      }
    GQL
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateAssignment", "errors")).to be_nil
    expect(result.dig("data", "updateAssignment", "assignment", "moderatedGrading", "enabled")).to be true
    expect(result.dig("data", "updateAssignment", "assignment", "moderatedGrading", "graderCount")).to eq 1
    expect(result.dig("data", "updateAssignment", "assignment", "moderatedGrading", "graderCommentsVisibleToGraders")).to be false
    expect(result.dig("data", "updateAssignment", "assignment", "moderatedGrading", "graderNamesVisibleToFinalGrader")).to be false

    # this will still be false because it requires graderCommentsVisibleToGraders to be true
    expect(result.dig("data", "updateAssignment", "assignment", "moderatedGrading", "gradersAnonymousToGraders")).to be false
    expect(result.dig("data", "updateAssignment", "assignment", "moderatedGrading", "finalGrader", "_id")).to eq @teacher.id.to_s
    assignment = Assignment.find(@assignment_id)
    expect(assignment.moderated_grading).to be true
    expect(assignment.grader_count).to eq 1
    expect(assignment.grader_comments_visible_to_graders).to be false
    expect(assignment.grader_names_visible_to_final_grader).to be false
    expect(assignment.graders_anonymous_to_graders).to be false
    expect(assignment.final_grader_id).to eq @teacher.id
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      moderatedGrading: {
        enabled: true
        graderCount: 1
        graderCommentsVisibleToGraders: true
        graderNamesVisibleToFinalGrader: false
        gradersAnonymousToGraders: true
        finalGraderId: "#{@teacher.id}"
      }
    GQL
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateAssignment", "errors")).to be_nil
    expect(result.dig("data", "updateAssignment", "assignment", "moderatedGrading", "gradersAnonymousToGraders")).to be true
    expect(Assignment.find(@assignment_id).graders_anonymous_to_graders).to be true
  end

  it "can update peerReviews" do
    assignment = Assignment.find(@assignment_id)
    expect(assignment.peer_reviews).to be false
    expect(assignment.peer_review_count).to eq 0
    expect(assignment.peer_reviews_due_at).to be_nil
    expect(assignment.intra_group_peer_reviews).to be false
    expect(assignment.anonymous_peer_reviews).to be false
    expect(assignment.automatic_peer_reviews).to be false
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      moderatedGrading: {
        graderCount: 1
      }
      peerReviews: {
        enabled: true
        count: 2
        dueAt: "2018-01-01T01:00:00Z"
        intraReviews: true
        anonymousReviews: true
        automaticReviews: true
      }
    GQL
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateAssignment", "errors")).to be_nil
    expect(result.dig("data", "updateAssignment", "assignment", "peerReviews", "enabled")).to be true
    expect(result.dig("data", "updateAssignment", "assignment", "peerReviews", "count")).to eq 2
    expect(result.dig("data", "updateAssignment", "assignment", "peerReviews", "dueAt")).to eq "2018-01-01T01:00:00Z"
    expect(result.dig("data", "updateAssignment", "assignment", "peerReviews", "intraReviews")).to be true
    expect(result.dig("data", "updateAssignment", "assignment", "peerReviews", "anonymousReviews")).to be true
    expect(result.dig("data", "updateAssignment", "assignment", "peerReviews", "automaticReviews")).to be true
    assignment = Assignment.find(@assignment_id)
    expect(assignment.peer_reviews).to be true
    expect(assignment.peer_review_count).to eq 2
    expect(assignment.peer_reviews_due_at).to eq "2018-01-01T01:00:00Z"
    expect(assignment.intra_group_peer_reviews).to be true
    expect(assignment.anonymous_peer_reviews).to be true
    expect(assignment.automatic_peer_reviews).to be true
  end

  it "enabling moderated grading sticks with other updates" do
    assignment = Assignment.find(@assignment_id)
    expect(assignment.moderated_grading).to be false
    expect(assignment.grader_count).to eq 0
    expect(assignment.final_grader_id).to be_nil
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      moderatedGrading: {
        enabled: true
        graderCount: 1
        finalGraderId: "#{@teacher.id}"
      }
    GQL
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateAssignment", "errors")).to be_nil
    expect(result.dig("data", "updateAssignment", "assignment", "moderatedGrading", "enabled")).to be true
    expect(result.dig("data", "updateAssignment", "assignment", "moderatedGrading", "graderCount")).to eq 1
    expect(result.dig("data", "updateAssignment", "assignment", "moderatedGrading", "finalGrader", "_id")).to eq @teacher.id.to_s
    assignment = Assignment.find(@assignment_id)
    expect(assignment.moderated_grading).to be true
    expect(assignment.grader_count).to eq 1
    expect(assignment.final_grader_id).to eq @teacher.id
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      moderatedGrading: {
        graderCount: 2
      }
    GQL
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateAssignment", "errors")).to be_nil
    expect(result.dig("data", "updateAssignment", "assignment", "moderatedGrading", "enabled")).to be true
    expect(result.dig("data", "updateAssignment", "assignment", "moderatedGrading", "graderCount")).to eq 2
    expect(result.dig("data", "updateAssignment", "assignment", "moderatedGrading", "finalGrader", "_id")).to eq @teacher.id.to_s
    assignment = Assignment.find(@assignment_id)
    expect(assignment.moderated_grading).to be true
    expect(assignment.grader_count).to eq 2
    expect(assignment.final_grader_id).to eq @teacher.id
  end

  it "can update assignmentGroupId" do
    expect(Assignment.find(@assignment_id).assignment_group.id).not_to be_nil
    new_assignment_group = @course.assignment_groups.create!
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      assignmentGroupId: "#{new_assignment_group.id}"
    GQL
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateAssignment", "errors")).to be_nil
    expect(result.dig("data", "updateAssignment", "assignment", "assignmentGroup", "_id")).to eq new_assignment_group.id.to_s
    expect(Assignment.find(@assignment_id).assignment_group.id).to eq new_assignment_group.id
  end

  it "can update groupSetId" do
    expect(Assignment.find(@assignment_id).group_category).to be_nil
    new_group_category = @course.group_categories.create!(name: "new group or stuffs")
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      groupSetId: "#{new_group_category.id}"
    GQL
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateAssignment", "errors")).to be_nil
    expect(result.dig("data", "updateAssignment", "assignment", "groupSet", "_id")).to eq new_group_category.id.to_s
    expect(Assignment.find(@assignment_id).group_category.id).to eq new_group_category.id
  end

  it "can update state" do
    expect(Assignment.find(@assignment_id).workflow_state).to eq "published"
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      state: unpublished
    GQL
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateAssignment", "errors")).to be_nil
    expect(result.dig("data", "updateAssignment", "assignment", "state")).to eq "unpublished"
    expect(Assignment.find(@assignment_id).workflow_state).to eq "unpublished"

    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      state: published
    GQL
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateAssignment", "errors")).to be_nil
    expect(result.dig("data", "updateAssignment", "assignment", "state")).to eq "published"
    expect(Assignment.find(@assignment_id).workflow_state).to eq "published"
  end

  it "can delete and then restore" do
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      state: deleted
      name: "Example Assignment (deleted)"
    GQL
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateAssignment", "errors")).to be_nil
    expect(result.dig("data", "updateAssignment", "assignment", "state")).to eq "deleted"
    expect(result.dig("data", "updateAssignment", "assignment", "name")).to eq "Example Assignment (deleted)"
    expect(Assignment.find(@assignment_id).name).to eq "Example Assignment (deleted)"
    expect(Assignment.find(@assignment_id).workflow_state).to eq "deleted"

    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      state: published
      name: "not deleted anymore!"
    GQL
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateAssignment", "errors")).to be_nil
    expect(result.dig("data", "updateAssignment", "assignment", "state")).to eq "published"
    expect(result.dig("data", "updateAssignment", "assignment", "name")).to eq "not deleted anymore!"
    expect(Assignment.find(@assignment_id).name).to eq "not deleted anymore!"
    expect(Assignment.find(@assignment_id).workflow_state).to eq "published"
  end

  it "can update to same state without error" do
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      state: deleted
    GQL
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateAssignment", "errors")).to be_nil
    expect(result.dig("data", "updateAssignment", "assignment", "state")).to eq "deleted"
    expect(Assignment.find(@assignment_id).workflow_state).to eq "deleted"

    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      state: deleted
    GQL
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateAssignment", "errors")).to be_nil
    expect(result.dig("data", "updateAssignment", "assignment", "state")).to eq "deleted"
    expect(Assignment.find(@assignment_id).workflow_state).to eq "deleted"

    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      state: published
    GQL
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateAssignment", "errors")).to be_nil
    expect(result.dig("data", "updateAssignment", "assignment", "state")).to eq "published"
    expect(Assignment.find(@assignment_id).workflow_state).to eq "published"

    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      state: published
    GQL
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateAssignment", "errors")).to be_nil
    expect(result.dig("data", "updateAssignment", "assignment", "state")).to eq "published"
    expect(Assignment.find(@assignment_id).workflow_state).to eq "published"
  end

  it "can add and remove itself from a module" do
    expect(Assignment.find(@assignment_id).context_module_tag_ids).to eq([])
    course_module1 = @course.context_modules.create!(name: "module-1")
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      moduleIds: ["#{course_module1.id}"]
    GQL
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateAssignment", "errors")).to be_nil
    expect(result.dig("data", "updateAssignment", "assignment", "modules").length).to eq 1
    expect(result.dig("data", "updateAssignment", "assignment", "modules", 0, "_id")).to eq course_module1.id.to_s
    expect(get_assignment_module_ids).to eq([course_module1.id])
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      moduleIds: []
    GQL
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateAssignment", "errors")).to be_nil
    expect(result.dig("data", "updateAssignment", "assignment", "modules").length).to eq 0
    expect(get_assignment_module_ids).to eq([])
  end

  it "can remove itself from a module when part of more than one" do
    expect(Assignment.find(@assignment_id).context_module_tag_ids).to eq([])
    course_module1 = create_module_and_add_assignment("module-1")
    course_module2 = create_module_and_add_assignment("module-2")
    course_module3 = create_module_and_add_assignment("module-3")
    expect(get_assignment_module_ids).to eq([course_module1.id, course_module2.id, course_module3.id])
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      moduleIds: ["#{course_module1.id}", "#{course_module3.id}"]
    GQL
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateAssignment", "errors")).to be_nil
    expect(result.dig("data", "updateAssignment", "assignment", "modules").length).to eq 2
    expect(result.dig("data", "updateAssignment", "assignment", "modules", 0, "_id")).to eq course_module1.id.to_s
    expect(result.dig("data", "updateAssignment", "assignment", "modules", 1, "_id")).to eq course_module3.id.to_s
    expect(get_assignment_module_ids).to eq([course_module1.id, course_module3.id])
  end

  it "can add itself from a module when part of more than one" do
    expect(Assignment.find(@assignment_id).context_module_tag_ids).to eq([])
    course_module1 = create_module_and_add_assignment("module-1")
    course_module2 = @course.context_modules.create!(name: "module-2")
    course_module3 = create_module_and_add_assignment("module-3")
    expect(get_assignment_module_ids).to eq([course_module1.id, course_module3.id])
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      moduleIds: ["#{course_module1.id}", "#{course_module2.id}", "#{course_module3.id}"]
    GQL
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateAssignment", "errors")).to be_nil
    expect(result.dig("data", "updateAssignment", "assignment", "modules").length).to eq 3
    expect(result.dig("data", "updateAssignment", "assignment", "modules", 0, "_id")).to eq course_module1.id.to_s
    expect(result.dig("data", "updateAssignment", "assignment", "modules", 1, "_id")).to eq course_module2.id.to_s
    expect(result.dig("data", "updateAssignment", "assignment", "modules", 2, "_id")).to eq course_module3.id.to_s
    expect(get_assignment_module_ids).to eq([course_module1.id, course_module2.id, course_module3.id])
  end

  it "does not remove itself from a module if in same module multiple times" do
    expect(Assignment.find(@assignment_id).context_module_tag_ids).to eq([])
    course_module1 = create_module_and_add_assignment("module-1")
    course_module1.add_item(id: @assignment_id, type: "assignment")
    expect(get_assignment_module_ids).to eq([course_module1.id, course_module1.id])
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      moduleIds: ["#{course_module1.id}"]
    GQL
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateAssignment", "errors")).to be_nil
    expect(result.dig("data", "updateAssignment", "assignment", "modules").length).to eq 2
    expect(result.dig("data", "updateAssignment", "assignment", "modules", 0, "_id")).to eq course_module1.id.to_s
    expect(result.dig("data", "updateAssignment", "assignment", "modules", 1, "_id")).to eq course_module1.id.to_s
    expect(get_assignment_module_ids).to eq([course_module1.id, course_module1.id])
  end

  it "does not error when a module is specified multiple times" do
    expect(Assignment.find(@assignment_id).context_module_tag_ids).to eq([])
    course_module1 = create_module_and_add_assignment("module-1")
    course_module1.add_item(id: @assignment_id, type: "assignment")
    expect(get_assignment_module_ids).to eq([course_module1.id, course_module1.id])
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      moduleIds: ["#{course_module1.id}", "#{course_module1.id}"]
    GQL
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateAssignment", "errors")).to be_nil
    expect(result.dig("data", "updateAssignment", "assignment", "modules").length).to eq 2
    expect(result.dig("data", "updateAssignment", "assignment", "modules", 0, "_id")).to eq course_module1.id.to_s
    expect(result.dig("data", "updateAssignment", "assignment", "modules", 1, "_id")).to eq course_module1.id.to_s
    expect(get_assignment_module_ids).to eq([course_module1.id, course_module1.id])
  end

  it "backend validation happens for moderated grading" do
    expect(Assignment.find(@assignment_id).moderated_grading).to be false
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      moderatedGrading: {enabled: true}
    GQL
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateAssignment", "assignment")).to be_nil
    expect(result.dig("data", "updateAssignment", "errors").length).to eq 2
    expect(result.dig("data", "updateAssignment", "errors", 0, "attribute")).to eq "grader_count"
    expect(result.dig("data", "updateAssignment", "errors", 0, "message")).to eq "must be greater than 0"
    expect(result.dig("data", "updateAssignment", "errors", 1, "attribute")).to eq "invalid_record"
    expect(Assignment.find(@assignment_id).moderated_grading).to be false
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
    context = { current_user: @teacher, request: ActionDispatch::TestRequest.create }
    result = CanvasSchema.execute(mutation_command, context:)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "changeName", "errors")).to be_nil
    expect(result.dig("data", "changeName", "assignment", "name")).to eq "Example Assignment (deleted)"
    expect(result.dig("data", "changeName", "assignment", "state")).to eq "published"
    expect(result.dig("data", "delete", "errors")).to be_nil
    expect(result.dig("data", "delete", "assignment", "name")).to eq "Example Assignment (deleted)"
    expect(result.dig("data", "delete", "assignment", "state")).to eq "deleted"
  end

  it "can handle not found gracefully" do
    result = execute_with_input <<~GQL
      id: "1234"
      state: deleted
    GQL
    errors = result["errors"]
    expect(errors).to_not be_nil
    expect(errors[0]["message"]).to eq "assignment not found: 1234"
  end

  it "can handle bad input gracefully" do
    result = execute_with_input <<~GQL
      id: "#{@assignment_id}"
      state: "deleted"
    GQL
    expect(
      result["errors"].pluck("path")
    ).to eq [
      %w[mutation updateAssignment input state]
    ]
  end

  xit "validate errors return correctly with override instrumenter (ADMIN-2407)" do
    mutation_command = <<~GQL
      mutation {
        updateAssignment(input: {
          id: "#{@assignment_id}"
          submissionTypes: [ wiki_page ]
        }) {
          assignment {
            _id dueAt lockAt unlockAt
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
    context = { current_user: @teacher, request: ActionDispatch::TestRequest.create, session: {} }
    result = CanvasSchema.execute(mutation_command, context:)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateAssignment", "assignment")).to be_nil
    expect(result.dig("data", "updateAssignment", "errors")).to_not be_nil
  end

  it "cannot update without correct permissions" do
    # bad student! dont delete the assignment
    result = execute_with_input(<<~GQL, @student)
      id: "#{@assignment_id}"
      state: deleted
    GQL
    errors = result["errors"]
    expect(errors).to_not be_nil
    expect(errors.length).to be 1
    expect(errors[0]["message"]).to eq "insufficient permission"
  end
end
