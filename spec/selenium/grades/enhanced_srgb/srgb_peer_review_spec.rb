# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

require_relative "../../helpers/gradebook_common"
require_relative "../pages/enhanced_srgb_page"

describe "Enhanced Individual Gradebook - Peer Review" do
  include_context "in-process server selenium tests"
  include GradebookCommon

  before(:once) do
    course_with_teacher(active_all: true)
    @course.enable_feature!(:peer_review_allocation_and_grading)
    @student1 = student_in_course(course: @course, active_all: true).user
    @student2 = student_in_course(course: @course, active_all: true).user

    # Create parent assignment
    @parent_assignment = @course.assignments.create!(
      title: "Parent Assignment",
      submission_types: "online_text_entry",
      points_possible: 100,
      peer_reviews: true
    )

    # Create peer review sub assignment
    @peer_review_assignment = PeerReviewSubAssignment.create!(
      parent_assignment: @parent_assignment,
      title: "Peer Review",
      points_possible: 50
    )

    # Create submissions for parent assignment with peer review sub assignment submissions
    @parent_assignment.submit_homework(@student1, body: "Student 1 submission")
    @parent_assignment.submit_homework(@student2, body: "Student 2 submission")

    # Grade parent submissions
    @parent_assignment.grade_student(@student1, grade: 85, grader: @teacher)
    @parent_assignment.grade_student(@student2, grade: 75, grader: @teacher)

    # Grade peer review sub assignments
    @peer_review_assignment.grade_student(@student1, grade: 40, grader: @teacher)
    @peer_review_assignment.grade_student(@student2, grade: 50, grader: @teacher)
  end

  before do
    user_session(@teacher)
  end

  # Critical UI interaction tests - these verify the end-to-end user journey
  # Note: Calculation and display logic are tested in unit tests:
  # - AssignmentInformation.test.tsx for submission type display
  # - EnhancedIndividualGradebook tests for submission extraction
  # - gradebookUtils.test.ts for calculation logic

  it "displays peer review assignment in assignment dropdown" do
    EnhancedSRGB.visit(@course.id)

    assignment_options = EnhancedSRGB.assignment_dropdown_options
    expect(assignment_options).to include("Parent Assignment")
    expect(assignment_options).to include("Peer Review")
  end

  it "displays peer review grade for student" do
    EnhancedSRGB.visit(@course.id)

    EnhancedSRGB.select_student(@student1)
    EnhancedSRGB.select_assignment(@peer_review_assignment)

    expect(EnhancedSRGB.main_grade_input.attribute("value")).to eq("40")
  end
end
