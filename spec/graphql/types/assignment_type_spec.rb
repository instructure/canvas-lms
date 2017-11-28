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
  let_once(:test_course) { Course.create! name: "TEST"}

  # create users
  let_once(:teacher) do
      teacher_in_course(active_all:true, course: test_course)
      @teacher
  end
  let_once(:test_student) { User.create }
  let_once(:user2) {User.create }

  # create assignment for course
  let(:assignment) do
    test_course.assignments.create(title: "some assignment",
                                   submission_types: ['online_text_entry'],
                                   workflow_state: "published")
  end
  # create assignment type from assignment
  let(:assignment_type) {GraphQLTypeTester.new(Types::AssignmentType, assignment)}

  it "has submissions that need grading" do
    # enroll users
    test_course.enroll_student(test_student, enrollment_state: 'active')
    test_course.enroll_student(user2, enrollment_state: 'active')

    # submit homework to assignment for each user
    assignment.submit_homework(test_student, { :body => "so cool", :submission_type => 'online_text_entry' })
    assignment.submit_homework(user2, { :body => "sooooo cool", :submission_type => 'online_text_entry' })

    # expect needs grading count to be the same for assignment and assignment type objects
    expect(assignment.needs_grading_count).to eq 2
    expect(assignment_type.needsGradingCount(current_user: teacher)).to eq 2
  end

  it "has the same data" do
    expect(assignment_type._id).to eq assignment.id
    expect(assignment_type.name).to eq assignment_type.name
    expect(assignment_type.state).to eq assignment.workflow_state
  end

  it "returns submissions from submission connection (with permissions)" do
    test_course.enroll_student(test_student, enrollment_state: 'active')
    submission = assignment.submit_homework(test_student, { :body => "sub1", :submission_type => 'online_text_entry' })

    expect(assignment_type.submissionsConnection(current_user: @teacher).length).to eq 1
    expect(assignment_type.submissionsConnection(current_user: @teacher)[0].id).to eq submission.id

    expect(assignment_type.submissionsConnection(current_user: @student)).to eq nil
  end

  it "can access it's parent course" do
    expect(assignment_type.course).to eq test_course
  end
end
