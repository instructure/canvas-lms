#
# Copyright (C) 2017 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/graphql_type_tester')

describe Types::AssignmentType do
  # create course
  let_once(:course) { course_factory(active_all: true) }

  # create users
  let_once(:teacher) do
      teacher_in_course(active_all:true, course: course)
      @teacher
  end
  let_once(:student) { student_in_course(course: course, active_all: true).user }

  # create assignment for course
  let(:assignment) do
    course.assignments.create(title: "some assignment",
                                   submission_types: ['online_text_entry'],
                                   workflow_state: "published")
  end
  # create assignment type from assignment
  let(:assignment_type) {GraphQLTypeTester.new(Types::AssignmentType, assignment)}

  it "has submissions that need grading" do
    # enroll users
    other_student = student_in_course(course: course, active_all: true).user

    # submit homework to assignment for each user
    assignment.submit_homework(student, { :body => "so cool", :submission_type => 'online_text_entry' })
    assignment.submit_homework(other_student, { :body => "sooooo cool", :submission_type => 'online_text_entry' })

    # expect needs grading count to be the same for assignment and assignment type objects
    expect(assignment.needs_grading_count).to eq 2
    expect(assignment_type.needsGradingCount(current_user: teacher)).to eq 2
  end

  it "has the same data" do
    expect(assignment_type._id).to eq assignment.id
    expect(assignment_type.name).to eq assignment_type.name
    expect(assignment_type.state).to eq assignment.workflow_state
    expect(assignment_type.onlyVisibleToOverrides).to eq assignment.only_visible_to_overrides
    expect(assignment_type.assignmentGroup).to eq assignment.assignment_group
    expect(assignment_type.dueAt).to eq assignment.due_at
    expect(assignment_type.lockAt).to eq assignment.lock_at
    expect(assignment_type.unlockAt).to eq assignment.unlock_at
    expect(assignment_type.muted).to eq assignment.muted?
  end

  describe "submissionsConnection" do
    let_once(:other_student) { student_in_course(course: course, active_all: true).user }

    it "returns 'real' submissions from with permissions" do
      submission1 = assignment.submit_homework(student, { :body => "sub1", :submission_type => 'online_text_entry' })
      submission2 = assignment.submit_homework(other_student, { :body => "sub1", :submission_type => 'online_text_entry' })

      expect(assignment_type.submissionsConnection(current_user: teacher).sort).to eq [submission1, submission2]
      expect(assignment_type.submissionsConnection(current_user: student)).to eq [submission1]
    end

    it "can filter submissions according to workflow state" do
      expect(assignment_type.submissionsConnection(current_user: teacher)).to eq []

      expect(
        assignment_type.submissionsConnection(
          current_user: teacher,
          args: { filter: { states: %w[unsubmitted] } }
        )
      ).to eq assignment.submissions
    end
  end

  it "can access it's parent course" do
    expect(assignment_type.course).to eq course
  end

  it "has an assignmentGroup" do
    expect(assignment_type.assignmentGroup).to eq assignment.assignment_group
  end

  it "only returns valid submission types" do
    assignment.update_attribute :submission_types, "none,foodfight"
    expect(assignment_type.submissionTypes).to eq ["none"]
  end

  it "returns (valid) grading types" do
    expect(assignment_type.gradingType).to eq assignment.grading_type

    assignment.update_attribute :grading_type, "fakefakefake"
    expect(assignment_type.gradingType).to be_nil
  end
end
