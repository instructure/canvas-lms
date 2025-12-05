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

require_relative "../common"

describe "peer review student landing page" do
  include_context "in-process server selenium tests"

  def loading_spinner
    f("span[class*='spinner']")
  end

  def visit_peer_reviews_page(course_id, assignment_id)
    get "/courses/#{course_id}/assignments/#{assignment_id}/peer_reviews"
    wait_for(method: nil, timeout: 5) { loading_spinner.displayed? == false }
    wait_for_ajaximations
  end

  before(:once) do
    Account.default.enable_feature!(:peer_review_allocation_and_grading)
    Account.default.enable_feature!(:assignments_2_student)
    Account.default.enable_feature!(:peer_reviews_for_a2)
    course_with_teacher(active_all: true)
    @student1 = student_in_course(name: "Student 1", course: @course, enrollment_state: :active).user
    @student2 = student_in_course(name: "Student 2", course: @course, enrollment_state: :active).user
    @student3 = student_in_course(name: "Student 3", course: @course, enrollment_state: :active).user
    @student4 = student_in_course(name: "Student 4", course: @course, enrollment_state: :active).user

    @assignment = assignment_model({
                                     course: @course,
                                     peer_reviews: true,
                                     automatic_peer_reviews: false,
                                     peer_review_count: 2,
                                     points_possible: 10,
                                     submission_types: "online_text_entry"
                                   })

    @assignment.submit_homework(@student1, body: "student 1 attempt", submission_type: "online_text_entry")
    @assignment.submit_homework(@student2, body: "student 2 attempt", submission_type: "online_text_entry")
    @assignment.submit_homework(@student3, body: "student 3 attempt", submission_type: "online_text_entry")
    @assignment.submit_homework(@student4, body: "student 4 attempt", submission_type: "online_text_entry")
  end

  before do
    user_session(@student1)
  end

  context "automatic peer review allocation" do
    it "automatically allocates peer reviews when student has no allocations" do
      visit_peer_reviews_page(@course.id, @assignment.id)

      expect(f("input[data-testid='peer-review-selector']")).to be_displayed

      submission = @assignment.submissions.find_by(user: @student1)
      assessment_requests = AssessmentRequest.where(assessor_asset: submission)
      expect(assessment_requests.count).to eq(2)
    end

    it "automatically allocates additional peer reviews when student has partial allocations" do
      @assignment.assign_peer_review(@student1, @student2)

      visit_peer_reviews_page(@course.id, @assignment.id)

      expect(f("input[data-testid='peer-review-selector']")).to be_displayed

      submission = @assignment.submissions.find_by(user: @student1)
      assessment_requests = AssessmentRequest.where(assessor_asset: submission)
      expect(assessment_requests.count).to eq(2)
    end

    it "does not allocate peer reviews when student has all required allocations" do
      @assignment.assign_peer_review(@student1, @student2)
      @assignment.assign_peer_review(@student1, @student3)

      submission = @assignment.submissions.find_by(user: @student1)
      initial_count = AssessmentRequest.where(assessor_asset: submission).count

      visit_peer_reviews_page(@course.id, @assignment.id)

      expect(f("input[data-testid='peer-review-selector']")).to be_displayed

      final_count = AssessmentRequest.where(assessor_asset: submission).count
      expect(final_count).to eq(initial_count)
      expect(final_count).to eq(2)
    end
  end

  context "peer review selector" do
    before do
      @assignment.assign_peer_review(@student1, @student2)
      @assignment.assign_peer_review(@student1, @student3)
    end

    it "displays peer review selector with correct options", custom_timeout: 30 do
      visit_peer_reviews_page(@course.id, @assignment.id)
      selector = f("input[data-testid='peer-review-selector']")
      expect(selector).to be_present
      options = INSTUI_Select_options(selector)
      option_names = options.map(&:text)
      expect(option_names).to contain_exactly("Peer Review (1 of 2)", "Peer Review (2 of 2)")

      click_INSTUI_Select_option(selector, option_names[1])
      expect(selector.attribute("value")).to eq(option_names[1])
    end

    it "shows a default message when no peer reviews are available", custom_timeout: 30 do
      no_peer_review_assignment = assignment_model({
                                                     course: @course,
                                                     peer_reviews: true,
                                                     automatic_peer_reviews: false,
                                                     points_possible: 10,
                                                     submission_types: "online_text_entry"
                                                   })

      visit_peer_reviews_page(@course.id, no_peer_review_assignment.id)
      selector = f("input[data-testid='peer-review-selector']")

      expect(selector).to be_present

      expect(selector.attribute("value")).to eq("No peer reviews available")
    end

    it "groups peer review assessments into ready to review and completed sections", custom_timeout: 30 do
      student5 = student_in_course(name: "Student 5", course: @course, enrollment_state: :active).user
      completed_assessment = @assignment.assign_peer_review(@student1, student5)

      @assignment.submit_homework(
        student5,
        body: "student 5 attempt",
        submission_type: "online_text_entry"
      )

      completed_assessment.complete!

      visit_peer_reviews_page(@course.id, @assignment.id)
      selector = f("input[data-testid='peer-review-selector']")
      expect(selector).to be_present

      options = INSTUI_Select_options(selector)
      option_texts = options.map(&:text)

      peer_review_options = option_texts.select { |text| text.include?("Peer Review") }
      expect(peer_review_options.count).to eq(3)

      expect(f("body")).to include_text("Ready to Review")
      expect(f("body")).to include_text("Completed Peer Reviews")
    end
  end
end
