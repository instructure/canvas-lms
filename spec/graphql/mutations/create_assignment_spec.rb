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

require "spec_helper"
require_relative "../graphql_spec_helper"

describe Mutations::CreateAssignment do
  before :once do
    @account = Account.default
    @course = @account.courses.create!
    @teacher = @course.enroll_teacher(User.create!, enrollment_state: 'active').user
    @student = @course.enroll_student(User.create!, enrollment_state: 'active').user
    @course.enable_feature!(:anonymous_marking)
  end

  def execute_with_input(create_input, user_executing: @teacher)
    mutation_command = <<~GQL
      mutation {
        createAssignment(input: {
          #{create_input}
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
    context = {current_user: user_executing, request: ActionDispatch::TestRequest.create, session: {}}
    CanvasSchema.execute(mutation_command, context: context)
  end

  TEST_ATTRS = [
    ["name", :name, "Example Assignment", '"some other assignment title"', "some other assignment title"],
    ["description", :description, nil, '"this is a description"', "this is a description"],
    ["dueAt", :due_at, nil, '"2018-01-01T01:00:00Z"', "2018-01-01T01:00:00Z"],
    ["lockAt", :lock_at, nil, '"2018-01-01T01:00:00Z"', "2018-01-01T01:00:00Z"],
    ["unlockAt", :unlock_at, nil, '"2018-01-01T01:00:00Z"', "2018-01-01T01:00:00Z"],
    ["position", :position, 1, 2, 2],
    ["pointsPossible", :points_possible, nil, 100, 100],
    ["gradingType", :grading_type, "points", "not_graded", "not_graded"],
    ["allowedExtensions", :allowed_extensions, [], '[ "docs", "blah" ]', [ "docs", "blah" ]],
    ["allowedAttempts", :allowed_attempts, nil, 10, 10],
    ["onlyVisibleToOverrides", :only_visible_to_overrides, false, true, true],
    ["submissionTypes", :submission_types, "none", '[ discussion_topic, not_graded ]', [ "discussion_topic", "not_graded" ], "discussion_topic,not_graded"],
    ["gradeGroupStudentsIndividually", :grade_group_students_individually, false, true, true],
    ["omitFromFinalGrade", :omit_from_final_grade, false, true, true],
    ["anonymousInstructorAnnotations", :anonymous_instructor_annotations, false, true, true],
    ["postToSis", :post_to_sis, false, true, true],
    ["anonymousGrading", :anonymous_grading, false, true, true],
  ]

  it "creates an assignment with attributes" do
    query = +"courseId: #{@course.to_param}\n"
    TEST_ATTRS.each do |graphql_name, assignment_name, initial_value, update_value, graphql_result, assignment_result = graphql_result|
      query << "#{graphql_name}: #{update_value}\n"
    end
    result = execute_with_input(query)
    expect(result.dig('errors')).to be_nil
    expect(result.dig('data', 'createAssignment', 'errors')).to be_nil
    assignment = Assignment.find(result.dig('data', 'createAssignment', 'assignment', '_id'))
    TEST_ATTRS.each do |graphql_name, assignment_name, initial_value, update_value, graphql_result, assignment_result = graphql_result|
      expect(result.dig('data', 'createAssignment', 'assignment', graphql_name)).to eq graphql_result
      expect(assignment.send(assignment_name)).to eq assignment_result
    end
  end

  it "creates a moderated grading assignment" do
    result = execute_with_input <<~GQL
      courseId: "#{@course.to_param}"
      name: "moderated grading test assignment"
      moderatedGrading: {
        enabled: true
        graderCount: 1
        graderCommentsVisibleToGraders: false
        graderNamesVisibleToFinalGrader: false
        gradersAnonymousToGraders: true
        finalGraderId: "#{@teacher.to_param}"
      }
    GQL
    expect(result.dig('errors')).to be_nil
    expect(result.dig('data', 'createAssignment', 'errors')).to be_nil
    expect(result.dig('data', 'createAssignment', 'assignment', 'name')).to eq 'moderated grading test assignment'
    expect(result.dig('data', 'createAssignment', 'assignment', 'moderatedGrading', 'enabled')).to eq true
    expect(result.dig('data', 'createAssignment', 'assignment', 'moderatedGrading', 'graderCount')).to eq 1
    expect(result.dig('data', 'createAssignment', 'assignment', 'moderatedGrading', 'graderCommentsVisibleToGraders')).to eq false
    expect(result.dig('data', 'createAssignment', 'assignment', 'moderatedGrading', 'graderNamesVisibleToFinalGrader')).to eq false
    expect(result.dig('data', 'createAssignment', 'assignment', 'moderatedGrading', 'gradersAnonymousToGraders')).to eq false
    expect(result.dig('data', 'createAssignment', 'assignment', 'moderatedGrading', 'finalGrader', "_id")).to eq @teacher.to_param

    assignment = Assignment.find(result.dig('data', 'createAssignment', 'assignment', '_id'))
    expect(assignment.name).to eq 'moderated grading test assignment'
    expect(assignment).to be_moderated_grading
    expect(assignment.grader_count).to eq 1
    expect(assignment).not_to be_grader_comments_visible_to_graders
    expect(assignment).not_to be_grader_names_visible_to_final_grader
    expect(assignment).not_to be_graders_anonymous_to_graders
    expect(assignment.final_grader).to eq @teacher
  end

  it "creates a peer review assignment" do
    result = execute_with_input <<~GQL
      courseId: "#{@course.to_param}"
      name: "peer review test assignment"
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
    expect(result.dig('errors')).to be_nil
    expect(result.dig('data', 'createAssignment', 'errors')).to be_nil
    expect(result.dig('data', 'createAssignment', 'assignment', 'peerReviews', 'enabled')).to eq true
    expect(result.dig('data', 'createAssignment', 'assignment', 'peerReviews', 'count')).to eq 2
    expect(result.dig('data', 'createAssignment', 'assignment', 'peerReviews', 'dueAt')).to eq "2018-01-01T01:00:00Z"
    expect(result.dig('data', 'createAssignment', 'assignment', 'peerReviews', 'intraReviews')).to eq true
    expect(result.dig('data', 'createAssignment', 'assignment', 'peerReviews', 'anonymousReviews')).to eq true
    expect(result.dig('data', 'createAssignment', 'assignment', 'peerReviews', 'automaticReviews')).to eq true

    assignment = Assignment.find(result.dig('data', 'createAssignment', 'assignment', '_id'))
    expect(assignment.name).to eq "peer review test assignment"
    expect(assignment.peer_reviews).to eq true
    expect(assignment.peer_review_count).to eq 2
    expect(assignment.peer_reviews_due_at).to eq "2018-01-01T01:00:00Z"
    expect(assignment.intra_group_peer_reviews).to eq true
    expect(assignment.anonymous_peer_reviews).to eq true
    expect(assignment.automatic_peer_reviews).to eq true
  end

  it "creates an assignment in an assignment group" do
    new_assignment_group = @course.assignment_groups.create!
    result = execute_with_input <<~GQL
      courseId: "#{@course.to_param}"
      name: "assignment in group"
      assignmentGroupId: "#{new_assignment_group.to_param}"
    GQL
    expect(result.dig('errors')).to be_nil
    expect(result.dig('data', 'createAssignment', 'errors')).to be_nil
    expect(result.dig('data', 'createAssignment', 'assignment', 'assignmentGroup', '_id')).to eq new_assignment_group.id.to_s

    assignment = Assignment.find(result.dig('data', 'createAssignment', 'assignment', '_id'))
    expect(assignment.assignment_group).to eq new_assignment_group
  end

  it "creates an assignment in a module" do
    course_module1 = @course.context_modules.create!(:name => "module-1")
    result = execute_with_input <<~GQL
      courseId: "#{@course.to_param}"
      name: "assignment in module"
      moduleIds: ["#{course_module1.id}"]
    GQL
    expect(result.dig('errors')).to be_nil
    expect(result.dig('data', 'createAssignment', 'errors')).to be_nil
    expect(result.dig('data', 'createAssignment', 'assignment', 'modules').length).to eq 1
    expect(result.dig('data', 'createAssignment', 'assignment', 'modules', 0, "_id")).to eq course_module1.id.to_s

    assignment = Assignment.find(result.dig('data', 'createAssignment', 'assignment', '_id'))
    expect(course_module1.content_tags.pluck(:content_type, :content_id)).to include ['Assignment', assignment.id]
  end

  it "creates an assignment with overrides" do
    # .round to avoid round-trip truncation errors, .change(min: 1) to avoid fancy midnight timebombs
    due1 = 1.day.from_now.round.change(min: 1)
    due2 = 2.days.from_now.round.change(min: 1)
    due3 = 3.days.from_now.round.change(min: 1)

    gc = @course.group_categories.create! name: 'foo'
    group = gc.groups.create! context: @course, name: 'baz'
    result = execute_with_input <<~GQL
      name: "assignment with overrides"
      courseId: "#{@course.to_param}"
      onlyVisibleToOverrides: true
      groupSetId: "#{gc.id}"
      assignmentOverrides: [
        {
          studentIds: [#{@student.to_param}]
          dueAt: "#{due1.iso8601}"
        },
        {
          groupId: #{group.to_param}
          dueAt: "#{due2.iso8601}"
        },
        {
          sectionId: #{@course.default_section.to_param}
          dueAt: "#{due3.iso8601}"
        }
      ]
    GQL

    assignment = Assignment.find(result.dig('data', 'createAssignment', 'assignment', '_id'))
    expect(assignment).to be_only_visible_to_overrides

    student_override = assignment.assignment_overrides.where(set_type: 'ADHOC').first
    expect(student_override.assignment_override_students.pluck(:user_id)).to include @student.id
    expect(student_override.due_at). to eq due1

    group_override = assignment.assignment_overrides.where(set_type: 'Group').first
    expect(group_override.set_id).to eq group.id
    expect(group_override.due_at).to eq due2

    section_override = assignment.assignment_overrides.where(set_type: 'CourseSection').first
    expect(section_override.set_id).to eq @course.default_section.id
    expect(section_override.due_at).to eq due3
  end

  it "requires a name" do
    result = execute_with_input <<~GQL
      courseId: "#{@course.to_param}"
    GQL
    errors = result.dig('errors')
    expect(errors).to_not be_nil
    expect(errors.first['message']).to include "Argument 'name' on InputObject 'CreateAssignmentInput' is required"
  end

  it "requires a non-empty name" do
    result = execute_with_input <<~GQL
      courseId: "#{@course.to_param}"
      name: ""
    GQL
    expect(result.dig('data', 'createAssignment', 'errors')[0]['message']).to eq "can't be blank"
  end

  it "can handle course not found gracefully" do
    result = execute_with_input <<~GQL
      courseId: "0"
      name: "nope"
    GQL
    errors = result.dig('errors')
    expect(errors).to_not be_nil
    expect(errors[0]['message']).to include 'invalid course'
  end

  it "cannot create without correct permissions" do
    result = execute_with_input(<<~GQL, user_executing: @student)
      courseId: "#{@course.to_param}"
      name: "I don't have permission to create this"
    GQL
    errors = result.dig('errors')
    expect(errors).to_not be_nil
    expect(errors[0]['message']).to include 'invalid course'
  end

end
