# frozen_string_literal: true

# Copyright (C) 2023 - present Instructure, Inc.
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
require_relative "../common"
require_relative "../../spec_helper"
require_relative "page_objects/assignments_index_page"
require_relative "../assignments_v2/page_objects/student_assignment_page_v2"

describe "assignments index peer reviews" do
  include_context "in-process server selenium tests"
  include AssignmentsIndexPage

  before(:once) do
    Account.default.enable_feature!(:assignments_2_student)
    Account.default.enable_feature!(:peer_reviews_for_a2)
    @course = course_factory(name: "course", active_course: true)
    @teacher = teacher_in_course(name: "teacher", course: @course, enrollment_state: :active).user
    @student1 = student_in_course(name: "Student 1", course: @course, enrollment_state: :active).user
    @student2 = student_in_course(name: "Student 2", course: @course, enrollment_state: :active).user
    @student3 = student_in_course(name: "Student 3", course: @course, enrollment_state: :active).user

    @peer_review_assignment = assignment_model({
                                                 course: @course,
                                                 peer_reviews: true,
                                                 automatic_peer_reviews: false,
                                                 points_possible: 10,
                                                 submission_types: "online_text_entry"
                                               })
    @peer_review_assignment.assign_peer_review(@student1, @student2)
    @peer_review_assignment.assign_peer_review(@student1, @student3)
  end

  before do
    user_session(@student1)
  end

  it "are linked under the assignment they are assigned for but show as unavailable before making a submission" do
    visit_assignments_index_page(@course.id)

    expect(peer_review_requests(@peer_review_assignment.id)).to include_text("Required Peer Review 1")
    expect(peer_review_requests(@peer_review_assignment.id)).to include_text("Required Peer Review 2")
    expect(peer_review_requests(@peer_review_assignment.id)).to include_text("Not Available")
  end

  it "will remind students that they need to submit before completing assigned reviews" do
    visit_assignments_index_page(@course.id)
    assessment_request(1, @peer_review_assignment.name).click

    expect(StudentAssignmentPageV2.peer_review_need_submission_reminder).to include_text("You must submit your own work before you can review your peers.")
  end

  it "will remind students if a review is not ready for them yet" do
    @peer_review_assignment.submit_homework(
      @student1,
      body: "student 1 attempt",
      submission_type: "online_text_entry"
    )
    visit_assignments_index_page(@course.id)
    assessment_request(1, @peer_review_assignment.name).click

    expect(StudentAssignmentPageV2.peer_review_unavailible_reminder).to include_text("There are no submissions available to review just yet.")
  end

  it "will display the reviewee's name under the assessment request" do
    @peer_review_assignment.submit_homework(
      @student1,
      body: "student 1 attempt",
      submission_type: "online_text_entry"
    )
    @peer_review_assignment.submit_homework(
      @student2,
      body: "student 1 attempt",
      submission_type: "online_text_entry"
    )
    @peer_review_assignment.submit_homework(
      @student3,
      body: "student 1 attempt",
      submission_type: "online_text_entry"
    )
    visit_assignments_index_page(@course.id)

    expect(peer_review_requests(@peer_review_assignment.id)).to include_text("Required Peer Review 1")
    expect(peer_review_requests(@peer_review_assignment.id)).to include_text("Required Peer Review 2")
    expect(peer_review_requests(@peer_review_assignment.id)).to include_text("Student 2")
    expect(peer_review_requests(@peer_review_assignment.id)).to include_text("Student 3")
  end

  it "will display the anonymous student under the assessment request" do
    @peer_review_assignment.update!(anonymous_peer_reviews: true)
    @peer_review_assignment.submit_homework(
      @student1,
      body: "student 1 attempt",
      submission_type: "online_text_entry"
    )
    @peer_review_assignment.submit_homework(
      @student2,
      body: "student 1 attempt",
      submission_type: "online_text_entry"
    )
    @peer_review_assignment.submit_homework(
      @student3,
      body: "student 1 attempt",
      submission_type: "online_text_entry"
    )
    visit_assignments_index_page(@course.id)

    expect(peer_review_requests(@peer_review_assignment.id)).to include_text("Required Peer Review 1")
    expect(peer_review_requests(@peer_review_assignment.id)).to include_text("Required Peer Review 2")
    expect(peer_review_requests(@peer_review_assignment.id)).to include_text("Anonymous Student")
  end

  it "will redirect them to the peer review if availible and the assessment is selected" do
    @peer_review_assignment.submit_homework(
      @student1,
      body: "student 1 attempt",
      submission_type: "online_text_entry"
    )
    @peer_review_assignment.submit_homework(
      @student2,
      body: "student 2 attempt",
      submission_type: "online_text_entry"
    )
    @peer_review_assignment.submit_homework(
      @student3,
      body: "student 3 attempt",
      submission_type: "online_text_entry"
    )
    visit_assignments_index_page(@course.id)
    assessment_request(1, @peer_review_assignment.name).click

    expect(StudentAssignmentPageV2.assignment_sub_header).to include_text("Peer: Student 2")
    expect(StudentAssignmentPageV2.comment_container).to include_text("Add a comment to complete your peer review. You will only see comments written by you.")
    expect(StudentAssignmentPageV2.attempt_tab).to include_text("student 2 attempt")
  end

  it "will redirect them to the anonymous peer review if availible and the assessment is selected" do
    @peer_review_assignment.update!(anonymous_peer_reviews: true)
    @peer_review_assignment.submit_homework(
      @student1,
      body: "student 1 attempt",
      submission_type: "online_text_entry"
    )
    @peer_review_assignment.submit_homework(
      @student2,
      body: "student 2 attempt",
      submission_type: "online_text_entry"
    )
    @peer_review_assignment.submit_homework(
      @student3,
      body: "student 3 attempt",
      submission_type: "online_text_entry"
    )
    visit_assignments_index_page(@course.id)
    assessment_request(1, @peer_review_assignment.name).click

    expect(StudentAssignmentPageV2.assignment_sub_header).to include_text("Peer: Anonymous student")
    expect(StudentAssignmentPageV2.comment_container).to include_text("Add a comment to complete your peer review. You will only see comments written by you.")
    expect(StudentAssignmentPageV2.attempt_tab).to include_text("student 2 attempt")
  end
end
