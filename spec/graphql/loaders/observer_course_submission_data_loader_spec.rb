# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../../spec_helper"

RSpec.describe Loaders::ObserverCourseSubmissionDataLoader do
  before :once do
    course_with_teacher(active_all: true)
    @observer = User.create!
    @student1 = User.create!
    @student2 = User.create!

    @course.enroll_student(@student1, enrollment_state: "active")
    @course.enroll_student(@student2, enrollment_state: "active")

    # Observer enrolls to observe student1 and student2
    @observer_enrollment1 = @course.observer_enrollments.create!(
      user: @observer,
      associated_user: @student1,
      workflow_state: "active"
    )
    @observer_enrollment2 = @course.observer_enrollments.create!(
      user: @observer,
      associated_user: @student2,
      workflow_state: "active"
    )

    # Create assignments and submissions
    @assignment1 = @course.assignments.create!(title: "Assignment 1", submission_types: "online_text_entry", workflow_state: "published")
    @assignment2 = @course.assignments.create!(title: "Assignment 2", submission_types: "online_text_entry", workflow_state: "published")

    # Explicitly create only the submissions we want
    @submission1_student1 = @assignment1.submit_homework(@student1, submission_type: "online_text_entry", body: "student1 assignment1")
    @submission2_student1 = @assignment2.submit_homework(@student1, submission_type: "online_text_entry", body: "student1 assignment2")
    @submission1_student2 = @assignment1.submit_homework(@student2, submission_type: "online_text_entry", body: "student2 assignment1")
    # NOTE: Canvas creates submissions for all assignments, so we expect 2 students × 2 assignments = 4 total submissions
  end

  def with_batch_loader(user, request: nil)
    GraphQL::Batch.batch do
      yield Loaders::ObserverCourseSubmissionDataLoader.for(current_user: user, request:)
    end
  end

  it "loads submissions for the first observed student by default" do
    submissions = with_batch_loader(@observer) { |loader| loader.load(@course) }

    # With no cookie selection, should default to first observed student
    # Canvas creates submissions for all assignments, so we get 1 student × 2 assignments = 2 submissions
    expect(submissions.length).to eq(2)
    student_ids = submissions.map(&:user_id).uniq
    expect(student_ids).to eq([@student1.id])

    # Verify we get the expected assignments
    assignment_ids = submissions.map(&:assignment_id).sort
    expect(assignment_ids).to include(@assignment1.id, @assignment2.id)
  end

  it "loads submissions for the selected observed student when cookie is set" do
    # Mock a request with cookies selecting the second student
    mock_request = instance_double(ActionDispatch::Request)
    mock_cookies = { "k5_observed_user_for_#{@observer.id}" => @student2.id.to_s }
    allow(mock_request).to receive(:cookies).and_return(mock_cookies)

    submissions = with_batch_loader(@observer, request: mock_request) { |loader| loader.load(@course) }

    # Should get submissions for the selected student (student2)
    expect(submissions.length).to eq(2)
    student_ids = submissions.map(&:user_id).uniq
    expect(student_ids).to eq([@student2.id])

    # Verify we get the expected assignments
    assignment_ids = submissions.map(&:assignment_id).sort
    expect(assignment_ids).to include(@assignment1.id, @assignment2.id)
  end

  it "returns submissions for current user when not an observer" do
    # Create a submission for the teacher
    @assignment1.submit_homework(@teacher, submission_type: "online_text_entry", body: "teacher submission")

    submissions = with_batch_loader(@teacher) { |loader| loader.load(@course) }

    expect(submissions.length).to eq(1)
    expect(submissions.first.user_id).to eq(@teacher.id)
  end

  it "returns empty array when current_user is nil" do
    submissions = with_batch_loader(nil) { |loader| loader.load(@course) }

    expect(submissions).to eq([])
  end

  it "filters out assignments with sub_assignments" do
    # Create an assignment with sub_assignments (like discussion checkpoints)
    parent_assignment = @course.assignments.create!(title: "Parent Assignment", has_sub_assignments: true)
    parent_assignment.submit_homework(@student1, submission_type: "online_text_entry", body: "parent submission")

    submissions = with_batch_loader(@observer) { |loader| loader.load(@course) }

    # Should not include the parent assignment submission
    assignment_ids = submissions.map(&:assignment_id)
    expect(assignment_ids).not_to include(parent_assignment.id)
    expect(assignment_ids).to include(@assignment1.id, @assignment2.id)
  end

  it "only includes published assignments" do
    # Create unpublished assignment
    unpublished_assignment = @course.assignments.create!(title: "Unpublished", workflow_state: "unpublished")
    unpublished_assignment.submit_homework(@student1, submission_type: "online_text_entry", body: "test")

    submissions = with_batch_loader(@observer) { |loader| loader.load(@course) }

    assignment_ids = submissions.map(&:assignment_id)
    expect(assignment_ids).not_to include(unpublished_assignment.id)
    expect(assignment_ids).to include(@assignment1.id, @assignment2.id)
  end
end
