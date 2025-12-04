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
    before do
      course_with_teacher(active_all: true)
      @course.enable_feature!(:peer_review_allocation_and_grading)
      @assignment = @course.assignments.create!(
        name: "Test Assignment",
        peer_review_count: 5,
        points_possible: 10,
        submission_types: "online_text_entry",
        peer_reviews: true,
        anonymous_peer_reviews: false,
        intra_group_peer_reviews: false,
        peer_review_submission_required: true,
        peer_review_across_sections: true
      )
      @assignment.create_peer_review_sub_assignment!(
        context: @course,
        points_possible: 5
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

    context "peer review configuration tray" do
      it "opens configuration tray when View Configuration button is clicked" do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        wait_for_ajaximations

        view_config_button = f("[data-testid='view-configuration-button']")
        view_config_button.click
        wait_for_ajaximations

        expect(f("[data-testid='peer-review-configuration-tray']")).to be_displayed
      end

      it "displays peer review configuration in tray" do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        wait_for_ajaximations

        view_config_button = f("[data-testid='view-configuration-button']")
        view_config_button.click
        wait_for_ajaximations

        tray = f("[data-testid='peer-review-configuration-tray']")
        expect(tray).to include_text("Reviews Required")
        expect(tray).to include_text("Points Per Review")
        expect(tray).to include_text("Total Points")
        expect(tray).to include_text("Across Sections")
        expect(tray).to include_text("Submission Req")
        expect(tray).to include_text("Anonymity")
      end

      it "closes configuration tray when close button is clicked" do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        wait_for_ajaximations

        view_config_button = f("[data-testid='view-configuration-button']")
        view_config_button.click
        wait_for_ajaximations

        expect(f("[data-testid='peer-review-configuration-tray']")).to be_displayed

        close_button = f("[data-testid='peer-review-config-tray-close-button']")
        close_button.click
        wait_for_ajaximations

        expect(f("#content")).not_to contain_css("[data-testid='peer-review-configuration-tray']")
      end

      it "displays 'Within Groups' field for group assignments" do
        group_category = @course.group_categories.create!(name: "Project Groups")
        @assignment.update!(group_category:)

        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        wait_for_ajaximations

        view_config_button = f("[data-testid='view-configuration-button']")
        view_config_button.click
        wait_for_ajaximations

        tray = f("[data-testid='peer-review-configuration-tray']")
        expect(tray).to include_text("Within Groups")
      end

      it "displays correct review count in configuration" do
        @assignment.update!(peer_review_count: 3)

        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        wait_for_ajaximations

        view_config_button = f("[data-testid='view-configuration-button']")
        view_config_button.click
        wait_for_ajaximations

        tray = f("[data-testid='peer-review-configuration-tray']")
        expect(tray).to include_text("Reviews Required")
        expect(tray).to include_text("3")
      end
    end
  end

  context "without peer_review_allocation_and_grading feature flag" do
    before(:once) do
      course_with_teacher(active_all: true)
      @course.disable_feature!(:peer_review_allocation_and_grading)
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
        submission_types: "online_text_entry",
        peer_reviews: true
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
