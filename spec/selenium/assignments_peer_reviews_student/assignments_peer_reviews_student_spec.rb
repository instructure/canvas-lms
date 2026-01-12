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
                                     submission_types: "online_text_entry",
                                     peer_review_submission_required: false
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
                                                     submission_types: "online_text_entry",
                                                     peer_review_submission_required: false
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

  context "comments tray integration" do
    before do
      @assignment.assign_peer_review(@student1, @student2)
    end

    it "shows toggle comments button in submission view", custom_timeout: 30 do
      visit_peer_reviews_page(@course.id, @assignment.id)

      submission_tab = f("div[id='tab-submission']")
      submission_tab.click
      wait_for_ajaximations

      toggle_button = f("button[data-testid='toggle-comments-button']")
      expect(toggle_button).to be_displayed
      expect(toggle_button.text).to include("Show Comments")
    end

    it "opens comments tray when toggle button is clicked", custom_timeout: 30 do
      visit_peer_reviews_page(@course.id, @assignment.id)

      submission_tab = f("div[id='tab-submission']")
      submission_tab.click
      wait_for_ajaximations

      toggle_button = f("button[data-testid='toggle-comments-button']")
      toggle_button.click
      wait_for_ajaximations

      expect(f("h2")).to include_text("Peer Comments")
      expect(toggle_button.text).to include("Hide Comments")
    end

    it "closes comments tray when toggle button is clicked again", custom_timeout: 30 do
      visit_peer_reviews_page(@course.id, @assignment.id)

      submission_tab = f("div[id='tab-submission']")
      submission_tab.click
      wait_for_ajaximations

      toggle_button = f("button[data-testid='toggle-comments-button']")
      toggle_button.click
      wait_for_ajaximations

      expect(f("h2")).to include_text("Peer Comments")

      toggle_button.click
      wait_for_ajaximations

      expect(toggle_button.text).to include("Show Comments")
      expect(f("div[id='submission']")).not_to contain_css("div[data-testid='comments-container']")
    end

    it "allows user to submit a comment", custom_timeout: 30 do
      visit_peer_reviews_page(@course.id, @assignment.id)

      submission_tab = f("div[id='tab-submission']")
      submission_tab.click
      wait_for_ajaximations

      toggle_button = f("button[data-testid='toggle-comments-button']")
      toggle_button.click
      wait_for_ajaximations

      comment_textarea = f("textarea[data-testid='comment-text-input']")
      comment_textarea.send_keys("This is a peer review comment")
      wait_for_ajaximations

      send_button = fj("button:contains('Send Comment')")
      send_button.click
      wait_for_ajaximations

      expect(f("body")).to include_text("This is a peer review comment")
    end

    it "displays submit peer review button", custom_timeout: 30 do
      visit_peer_reviews_page(@course.id, @assignment.id)

      submission_tab = f("div[id='tab-submission']")
      submission_tab.click
      wait_for_ajaximations

      submit_button = f("button[data-testid='submit-peer-review-button']")
      expect(submit_button).to be_displayed
      expect(submit_button.text).to include("Submit Peer Review")
    end

    it "maintains comments tray state when switching between peer reviews", custom_timeout: 30 do
      @assignment.assign_peer_review(@student1, @student3)

      visit_peer_reviews_page(@course.id, @assignment.id)

      submission_tab = f("div[id='tab-submission']")
      submission_tab.click
      wait_for_ajaximations

      toggle_button = f("button[data-testid='toggle-comments-button']")
      toggle_button.click
      wait_for_ajaximations

      expect(f("h2")).to include_text("Peer Comments")

      selector = f("input[data-testid='peer-review-selector']")
      click_INSTUI_Select_option(selector, "Peer Review (2 of 2)")
      wait_for_ajaximations

      expect(toggle_button.text).to include("Hide Comments")
    end
  end

  context "peer review comment completion" do
    before do
      @assessment_request = @assignment.assign_peer_review(@student1, @student2)
    end

    it "marks assessment request as completed when comment is submitted", custom_timeout: 30 do
      visit_peer_reviews_page(@course.id, @assignment.id)

      submission_tab = f("div[id='tab-submission']")
      submission_tab.click
      wait_for_ajaximations

      toggle_button = f("button[data-testid='toggle-comments-button']")
      toggle_button.click
      wait_for_ajaximations

      comment_textarea = f("textarea[data-testid='comment-text-input']")
      comment_textarea.send_keys("Completing this peer review with a comment")
      wait_for_ajaximations

      send_button = fj("button:contains('Send Comment')")
      send_button.click
      wait_for_ajaximations

      @assessment_request.reload
      expect(@assessment_request.workflow_state).to eq("completed")
    end

    it "persists assessment request completion state after page reload", custom_timeout: 30 do
      @assignment.assign_peer_review(@student1, @student3)
      visit_peer_reviews_page(@course.id, @assignment.id)

      submission_tab = f("div[id='tab-submission']")
      submission_tab.click
      wait_for_ajaximations

      toggle_button = f("button[data-testid='toggle-comments-button']")
      toggle_button.click
      wait_for_ajaximations

      comment_textarea = f("textarea[data-testid='comment-text-input']")
      comment_textarea.send_keys("Test comment for persistence")
      wait_for_ajaximations

      send_button = fj("button:contains('Send Comment')")
      send_button.click
      wait_for_ajaximations

      # Reload the page
      visit_peer_reviews_page(@course.id, @assignment.id)
      wait_for_ajaximations

      keep_trying_until { @assessment_request.reload.workflow_state == "completed" }
      selector = f("input[data-testid='peer-review-selector']")
      selector.click
      wait_for_ajaximations

      expect(f("body")).to include_text("Completed Peer Reviews")
      expect(f("body")).to include_text("Ready to Review")
    end

    it "does not mark assessment request as completed when only viewing without commenting", custom_timeout: 30 do
      visit_peer_reviews_page(@course.id, @assignment.id)

      submission_tab = f("div[id='tab-submission']")
      submission_tab.click
      wait_for_ajaximations

      toggle_button = f("button[data-testid='toggle-comments-button']")
      toggle_button.click
      wait_for_ajaximations

      # Just open and close comments without submitting
      toggle_button.click
      wait_for_ajaximations

      @assessment_request.reload
      expect(@assessment_request.workflow_state).to eq("assigned")
    end
  end

  context "submit peer review button" do
    it "switches to next peer review after submitting first review", custom_timeout: 30 do
      visit_peer_reviews_page(@course.id, @assignment.id)

      submission_tab = f("div[id='tab-submission']")
      submission_tab.click
      wait_for_ajaximations

      selector = f("input[data-testid='peer-review-selector']")
      expect(selector.attribute("value")).to eq("Peer Review (1 of 2)")

      toggle_button = f("button[data-testid='toggle-comments-button']")
      toggle_button.click
      wait_for_ajaximations

      comment_textarea = f("textarea[data-testid='comment-text-input']")
      comment_textarea.send_keys("First peer review comment")
      wait_for_ajaximations

      send_button = fj("button:contains('Send Comment')")
      send_button.click
      wait_for_ajaximations

      submit_button = f("button[data-testid='submit-peer-review-button']")
      submit_button.click
      wait_for_ajaximations

      expect(selector.attribute("value")).to eq("Peer Review (2 of 2)")
    end

    it "shows error alert when attempting to submit without leaving a comment", custom_timeout: 30 do
      visit_peer_reviews_page(@course.id, @assignment.id)

      submission_tab = f("div[id='tab-submission']")
      submission_tab.click
      wait_for_ajaximations

      submit_button = f("button[data-testid='submit-peer-review-button']")
      submit_button.click
      wait_for_ajaximations

      expect(f("body")).to include_text("Before you can submit this peer review, you must leave a comment for your peer.")
    end

    it "shows peer review modal after completing all peer reviews", custom_timeout: 30 do
      @assignment.update(peer_review_count: 1)
      visit_peer_reviews_page(@course.id, @assignment.id)

      submission_tab = f("div[id='tab-submission']")
      submission_tab.click
      wait_for_ajaximations

      toggle_button = f("button[data-testid='toggle-comments-button']")
      toggle_button.click
      wait_for_ajaximations

      comment_textarea = f("textarea[data-testid='comment-text-input']")
      comment_textarea.send_keys("First peer review comment")
      wait_for_ajaximations

      send_button = fj("button:contains('Send Comment')")
      send_button.click
      wait_for_ajaximations

      submit_button = f("button[data-testid='submit-peer-review-button']")
      submit_button.click
      wait_for_ajaximations

      expect(f("body")).to include_text("You have completed your Peer Reviews!")
    end

    it "navigates through multiple peer reviews and shows modal after completing all", custom_timeout: 30 do
      visit_peer_reviews_page(@course.id, @assignment.id)

      submission_tab = f("div[id='tab-submission']")
      submission_tab.click
      wait_for_ajaximations

      selector = f("input[data-testid='peer-review-selector']")
      expect(selector.attribute("value")).to eq("Peer Review (1 of 2)")

      toggle_button = f("button[data-testid='toggle-comments-button']")
      toggle_button.click
      wait_for_ajaximations

      comment_textarea = f("textarea[data-testid='comment-text-input']")
      comment_textarea.send_keys("First peer review comment")
      wait_for_ajaximations

      send_button = fj("button:contains('Send Comment')")
      send_button.click
      wait_for_ajaximations

      submit_button = f("button[data-testid='submit-peer-review-button']")
      submit_button.click
      wait_for_ajaximations

      expect(selector.attribute("value")).to eq("Peer Review (2 of 2)")
      expect(f("body")).not_to include_text("You have completed your Peer Reviews!")

      comment_textarea = f("textarea[data-testid='comment-text-input']")
      comment_textarea.send_keys("Second peer review comment")
      wait_for_ajaximations

      send_button = fj("button:contains('Send Comment')")
      send_button.click
      wait_for_ajaximations

      submit_button = f("button[data-testid='submit-peer-review-button']")
      submit_button.click
      wait_for_ajaximations

      expect(f("body")).to include_text("You have completed your Peer Reviews!")
    end

    it "hides submit button after modal is shown", custom_timeout: 30 do
      @assignment.update(peer_review_count: 1)
      visit_peer_reviews_page(@course.id, @assignment.id)

      submission_tab = f("div[id='tab-submission']")
      submission_tab.click
      wait_for_ajaximations

      toggle_button = f("button[data-testid='toggle-comments-button']")
      toggle_button.click
      wait_for_ajaximations

      comment_textarea = f("textarea[data-testid='comment-text-input']")
      comment_textarea.send_keys("Peer review comment")
      wait_for_ajaximations

      send_button = fj("button:contains('Send Comment')")
      send_button.click
      wait_for_ajaximations

      submit_button = f("button[data-testid='submit-peer-review-button']")
      submit_button.click
      wait_for_ajaximations

      expect(f("body")).to include_text("You have completed your Peer Reviews!")

      # Wait for modal animation to complete and close button to be clickable
      close_button = fj("button:contains('Close')")
      wait_for_animations
      driver.action.move_to(close_button).click.perform
      wait_for_ajaximations

      expect(f("div[id='submission']")).not_to contain_css("button[data-testid='submit-peer-review-button']")
    end
  end

  context "rubric functionality" do
    before(:once) do
      @rubric = @course.rubrics.create!(
        title: "Peer Review Rubric",
        user: @teacher,
        context: @course,
        data: [
          {
            points: 4,
            description: "Quality",
            id: "criterion_1",
            ratings: [
              { description: "Excellent", points: 4, id: "rating_1" },
              { description: "Good", points: 3, id: "rating_2" },
              { description: "Fair", points: 2, id: "rating_3" },
              { description: "Poor", points: 0, id: "rating_4" }
            ]
          },
          {
            points: 6,
            description: "Completeness",
            id: "criterion_2",
            ratings: [
              { description: "Complete", points: 6, id: "rating_5" },
              { description: "Mostly Complete", points: 4, id: "rating_6" },
              { description: "Incomplete", points: 0, id: "rating_7" }
            ]
          }
        ],
        points_possible: 10
      )
      @rubric.associate_with(@assignment, @course, purpose: "grading")
    end

    it "shows rubric button when assignment has rubric", custom_timeout: 30 do
      visit_peer_reviews_page(@course.id, @assignment.id)

      submission_tab = f("div[id='tab-submission']")
      submission_tab.click
      wait_for_ajaximations

      toggle_rubric_button = f("button[data-testid='toggle-rubric-button']")
      expect(toggle_rubric_button).to be_displayed
      expect(toggle_rubric_button.text).to include("Show Rubric")
    end

    it "opens rubric panel when rubric button is clicked", custom_timeout: 30 do
      visit_peer_reviews_page(@course.id, @assignment.id)

      submission_tab = f("div[id='tab-submission']")
      submission_tab.click
      wait_for_ajaximations

      toggle_rubric_button = f("button[data-testid='toggle-rubric-button']")
      toggle_rubric_button.click
      wait_for_ajaximations

      expect(f("h2")).to include_text("Peer Review Rubric")
      expect(toggle_rubric_button.text).to include("Hide Rubric")
    end

    it "closes rubric panel when rubric button is clicked again", custom_timeout: 30 do
      visit_peer_reviews_page(@course.id, @assignment.id)

      submission_tab = f("div[id='tab-submission']")
      submission_tab.click
      wait_for_ajaximations

      toggle_rubric_button = f("button[data-testid='toggle-rubric-button']")
      toggle_rubric_button.click
      wait_for_ajaximations

      expect(f("h2")).to include_text("Peer Review Rubric")

      toggle_rubric_button.click
      wait_for_ajaximations

      expect(toggle_rubric_button.text).to include("Show Rubric")
      expect(f("body")).not_to include_text("Peer Review Rubric")
    end

    it "closes rubric panel when close button is clicked", custom_timeout: 30 do
      visit_peer_reviews_page(@course.id, @assignment.id)

      submission_tab = f("div[id='tab-submission']")
      submission_tab.click
      wait_for_ajaximations

      toggle_rubric_button = f("button[data-testid='toggle-rubric-button']")
      toggle_rubric_button.click
      wait_for_ajaximations

      close_button = f("[data-testid='close-rubric-button']")
      close_button.click
      wait_for_ajaximations

      expect(toggle_rubric_button.text).to include("Show Rubric")
    end

    it "closes comments when rubric is opened", custom_timeout: 30 do
      visit_peer_reviews_page(@course.id, @assignment.id)

      submission_tab = f("div[id='tab-submission']")
      submission_tab.click
      wait_for_ajaximations

      toggle_comments_button = f("button[data-testid='toggle-comments-button']")
      toggle_comments_button.click
      wait_for_ajaximations

      expect(f("h2")).to include_text("Peer Comments")

      toggle_rubric_button = f("button[data-testid='toggle-rubric-button']")
      toggle_rubric_button.click
      wait_for_ajaximations

      expect(f("h2")).to include_text("Peer Review Rubric")
      expect(f("body")).not_to include_text("Peer Comments")
    end

    it "closes rubric when comments are opened", custom_timeout: 30 do
      visit_peer_reviews_page(@course.id, @assignment.id)

      submission_tab = f("div[id='tab-submission']")
      submission_tab.click
      wait_for_ajaximations

      toggle_rubric_button = f("button[data-testid='toggle-rubric-button']")
      toggle_rubric_button.click
      wait_for_ajaximations

      expect(f("h2")).to include_text("Peer Review Rubric")

      toggle_comments_button = f("button[data-testid='toggle-comments-button']")
      toggle_comments_button.click
      wait_for_ajaximations

      expect(f("h2")).to include_text("Peer Comments")
      expect(f("body")).not_to include_text("Peer Review Rubric")
    end

    it "allows student to submit rubric assessment", custom_timeout: 30 do
      visit_peer_reviews_page(@course.id, @assignment.id)

      submission_tab = f("div[id='tab-submission']")
      submission_tab.click
      wait_for_ajaximations

      toggle_rubric_button = f("button[data-testid='toggle-rubric-button']")
      toggle_rubric_button.click
      wait_for_ajaximations

      expect(f("[data-testid='enhanced-rubric-assessment-container']")).to be_displayed

      fj("[data-testid='rubric-assessment-vertical-display'] button[data-testid='rubric-rating-button-3']:first").click
      wait_for_ajaximations

      fj("[data-testid='rubric-assessment-vertical-display'] button[data-testid='rubric-rating-button-2']:eq(1)").click
      wait_for_ajaximations

      f("[data-testid='save-rubric-assessment-button']").click
      wait_for_ajaximations

      submission = @assignment.submissions.find_by(user: @student2)
      rubric_assessment = submission.rubric_assessments.find_by(assessor: @student1, assessment_type: "peer_review")
      expect(rubric_assessment).not_to be_nil
      expect(rubric_assessment.score).to eq(10)
    end

    it "shows error when attempting to submit peer review without completing rubric", custom_timeout: 30 do
      visit_peer_reviews_page(@course.id, @assignment.id)

      submission_tab = f("div[id='tab-submission']")
      submission_tab.click
      wait_for_ajaximations

      submit_button = f("button[data-testid='submit-peer-review-button']")
      submit_button.click
      wait_for_ajaximations

      expect(f("body")).to include_text("You must fill out the rubric in order to submit your peer review.")
    end

    it "allows peer review submission when rubric is completed", custom_timeout: 30 do
      @assignment.assign_peer_review(@student1, @student3)

      visit_peer_reviews_page(@course.id, @assignment.id)

      submission_tab = f("div[id='tab-submission']")
      submission_tab.click
      wait_for_ajaximations

      selector = f("input[data-testid='peer-review-selector']")
      expect(selector.attribute("value")).to eq("Peer Review (1 of 2)")

      toggle_rubric_button = f("button[data-testid='toggle-rubric-button']")
      toggle_rubric_button.click
      wait_for_ajaximations

      expect(f("[data-testid='enhanced-rubric-assessment-container']")).to be_displayed

      fj("[data-testid='rubric-assessment-vertical-display'] button[data-testid='rubric-rating-button-3']:first").click
      wait_for_ajaximations

      fj("[data-testid='rubric-assessment-vertical-display'] button[data-testid='rubric-rating-button-2']:eq(1)").click
      wait_for_ajaximations

      f("[data-testid='save-rubric-assessment-button']").click
      wait_for_ajaximations

      submit_button = f("button[data-testid='submit-peer-review-button']")
      submit_button.click
      wait_for_ajaximations

      expect(selector.attribute("value")).to eq("Peer Review (2 of 2)")
    end
  end
end
