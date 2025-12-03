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
require_relative "../helpers/assignments_common"

describe "assignment peer review widget" do
  include_context "in-process server selenium tests"
  include AssignmentsCommon

  context "with peer_review_allocation_and_grading feature flag" do
    before(:once) do
      course_with_teacher(active_all: true)
      @course.enable_feature!(:peer_review_allocation_and_grading)
      @assignment = @course.assignments.create!(
        name: "Test Assignment",
        points_possible: 10,
        submission_types: "online_text_entry",
        peer_reviews: true
      )
    end

    before do
      user_session(@teacher)
    end

    it "displays the peer review widget on assignment show page" do
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      wait_for_ajaximations

      expect(f("#peer-review-assignment-widget-mount-point")).to be_displayed
    end

    it "displays View Configuration button" do
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      wait_for_ajaximations

      view_config_button = f("[data-testid='view-configuration-button']")
      expect(view_config_button).to be_displayed
      expect(view_config_button).to include_text("View Configuration")
    end

    it "displays Allocate Peer Reviews button" do
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      wait_for_ajaximations

      allocate_button = f("[data-testid='allocate-peer-reviews-button']")
      expect(allocate_button).to be_displayed
      expect(allocate_button).to include_text("Allocate Peer Reviews")
    end

    it "does not display the widget when peer reviews are disabled on the assignment" do
      @assignment.update!(peer_reviews: false)
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      wait_for_ajaximations

      expect(f("#content")).not_to contain_css("#peer-review-assignment-widget-mount-point")
    end
  end

  context "without peer_review_allocation_and_grading feature flag" do
    before(:once) do
      course_with_teacher(active_all: true)
      @course.disable_feature!(:peer_review_allocation_and_grading)
      @assignment = @course.assignments.create!(
        name: "Test Assignment",
        points_possible: 10,
        submission_types: "online_text_entry"
      )
    end

    before do
      user_session(@teacher)
    end

    it "does not display the peer review widget" do
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      wait_for_ajaximations

      expect(f("#content")).not_to contain_css("#peer-review-assignment-widget-mount-point")
    end
  end

  context "as a student" do
    before(:once) do
      course_with_student(active_all: true)
      @course.enable_feature!(:peer_review_allocation_and_grading)
      @assignment = @course.assignments.create!(
        name: "Test Assignment",
        points_possible: 10,
        submission_types: "online_text_entry"
      )
    end

    before do
      user_session(@student)
    end

    it "does not display the peer review widget to students" do
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      wait_for_ajaximations

      expect(f("#content")).not_to contain_css("#peer-review-assignment-widget-mount-point")
    end
  end
end
