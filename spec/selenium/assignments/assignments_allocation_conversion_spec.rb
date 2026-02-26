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

require_relative "../common"

describe "legacy allocation conversion" do
  include_context "in-process server selenium tests"

  before(:once) do
    course_with_teacher(active_all: true)
    @course.enable_feature!(:peer_review_allocation_and_grading)
    @student1 = student_in_course(course: @course, active_all: true, name: "Student 1").user
    @student2 = student_in_course(course: @course, active_all: true, name: "Student 2").user
  end

  before do
    user_session(@teacher)
  end

  def create_assignment_with_legacy_allocations
    @assignment = @course.assignments.create!(
      name: "peer review assignment",
      due_at: 5.days.from_now,
      points_possible: 10,
      submission_types: "online_text_entry",
      workflow_state: "published",
      peer_reviews: true,
      peer_review_count: 1
    )

    @assignment.assign_peer_review(@student1, @student2)

    PeerReview::PeerReviewCreatorService.call(parent_assignment: @assignment)
    @assignment.reload

    # Ensure the sub-assignment timestamp is strictly after the assessment request
    sub_assignment = @assignment.peer_review_sub_assignment
    legacy_request = AssessmentRequest.for_assignment(@assignment.id).incomplete.first
    if legacy_request && sub_assignment && legacy_request.created_at >= sub_assignment.created_at
      sub_assignment.update_column(:created_at, legacy_request.created_at + 1.second)
    end
  end

  def open_allocation_tray
    get "/courses/#{@course.id}/assignments/#{@assignment.id}"
    wait_for_ajaximations

    f("[data-testid='allocate-peer-reviews-button']").click
    wait_for_ajaximations
  end

  context "when legacy allocations exist" do
    before(:once) do
      create_assignment_with_legacy_allocations
    end

    it "shows the legacy allocations warning alert with convert and delete buttons" do
      open_allocation_tray

      expect(f("[data-testid='legacy-allocations-alert']")).to be_displayed
      expect(f("button[data-testid='legacy-allocations-convert-button']")).to be_displayed
      expect(f("button[data-testid='legacy-allocations-delete-button']")).to be_displayed
    end

    it "hides the add rule button while legacy allocations exist" do
      open_allocation_tray

      expect(f("body")).not_to contain_css("[data-testid='add-rule-button']")
    end
  end

  context "conversion flow" do
    before do
      create_assignment_with_legacy_allocations
    end

    it "converts legacy allocations and shows success message" do
      open_allocation_tray

      f("button[data-testid='legacy-allocations-convert-button']").click
      wait_for_ajaximations

      # Run the background conversion job
      run_jobs

      # Wait for polling to pick up the completed status
      wait_for(method: nil, timeout: 10) do
        !element_exists?("div[data-testid='legacy-allocations-converting-alert']") &&
          !element_exists?("div[data-testid='legacy-allocations-alert']")
      end

      expect_instui_flash_message("Allocations have been converted successfully.")
      expect(element_exists?("div[data-testid='legacy-allocations-alert']")).to be_falsey
      expect(f("[data-testid='add-rule-button']")).to be_displayed

      expect(f("[data-testid='allocation-rules-list']")).to be_displayed
      allocation_cards = ff("[data-testid='allocation-rule-card-wrapper']")
      expect(allocation_cards.length).to eq(1)
    end
  end

  context "deletion flow" do
    before do
      create_assignment_with_legacy_allocations
    end

    it "deletes legacy allocations and shows success message" do
      open_allocation_tray

      f("button[data-testid='legacy-allocations-delete-button']").click
      wait_for_ajaximations

      # Run the background deletion job
      run_jobs

      # Wait for polling to pick up the completed status
      wait_for(method: nil, timeout: 10) do
        !element_exists?("div[data-testid='legacy-allocations-converting-alert']") &&
          !element_exists?("div[data-testid='legacy-allocations-alert']")
      end

      expect_instui_flash_message("Allocations have been deleted successfully.")
      expect(element_exists?("div[data-testid='legacy-allocations-alert']")).to be_falsey
      expect(f("[data-testid='add-rule-button']")).to be_displayed
      expect(f("body")).not_to contain_css("[data-testid='allocation-rules-list']")
    end
  end

  context "when no legacy allocations exist" do
    before(:once) do
      @clean_assignment = @course.assignments.create!(
        name: "clean peer review assignment",
        due_at: 5.days.from_now,
        points_possible: 10,
        submission_types: "online_text_entry",
        workflow_state: "published",
        peer_reviews: true,
        peer_review_count: 1
      )
      PeerReview::PeerReviewCreatorService.call(parent_assignment: @clean_assignment)
    end

    it "shows + Rule button immediately without legacy prompt" do
      get "/courses/#{@course.id}/assignments/#{@clean_assignment.id}"
      wait_for_ajaximations
      f("[data-testid='allocate-peer-reviews-button']").click
      wait_for_ajaximations

      expect(f("[data-testid='add-rule-button']")).to be_displayed
      expect(f("body")).not_to contain_css("[data-testid='legacy-allocations-alert']")
      expect(f("body")).not_to contain_css("[data-testid='allocation-rules-list']")
    end
  end
end
