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

    it "does not display the Peer Reviews link in the right-side panel" do
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      wait_for_ajaximations

      # The old "Peer Reviews" link should not be displayed
      expect(f("#content")).not_to contain_css(".assignment_peer_reviews_link")
    end

    context "allocation tray integration" do
      before do
        @student1 = student_in_course(course: @course, active_all: true, name: "Student 1").user
        @student2 = student_in_course(course: @course, active_all: true, name: "Student 2").user
      end

      it "opens allocation tray when Allocate Peer Reviews button is clicked" do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        wait_for_ajaximations

        allocate_button = f("[data-testid='allocate-peer-reviews-button']")
        allocate_button.click
        wait_for_ajaximations

        expect(f("[data-testid='allocation-rules-tray']")).to be_displayed
      end

      it "closes allocation tray when close button is clicked" do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        wait_for_ajaximations

        allocate_button = f("[data-testid='allocate-peer-reviews-button']")
        allocate_button.click
        wait_for_ajaximations

        expect(f("[data-testid='allocation-rules-tray']")).to be_displayed

        close_button = f("span[data-testid='allocation-rules-tray-close-button'] button")
        close_button.click
        wait_for_ajaximations

        expect(f("body")).not_to contain_css('span[data-testid="allocation-rules-tray-close-button"]')
      end

      it "shows Add Rule button when teacher has edit permissions" do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        wait_for_ajaximations

        allocate_button = f("[data-testid='allocate-peer-reviews-button']")
        allocate_button.click
        wait_for_ajaximations

        expect(f("[data-testid='add-rule-button']")).to be_displayed
      end

      it "allows creating allocation rules from the widget's tray" do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        wait_for_ajaximations

        allocate_button = f("[data-testid='allocate-peer-reviews-button']")
        allocate_button.click
        wait_for_ajaximations

        add_rule_button = f("[data-testid='add-rule-button']")
        add_rule_button.click
        wait_for_ajaximations

        expect(f("span[data-testid='create-rule-modal']")).to be_displayed

        target_input = f("input#target-select")
        target_input.send_keys(@student1.name)
        wait_for_ajaximations
        fj("span[role='option']:contains('#{@student1.name}')").click
        wait_for_ajaximations

        subject_input = f("input#subject-select-main")
        subject_input.send_keys(@student2.name)
        wait_for_ajaximations
        fj("span[role='option']:contains('#{@student2.name}')").click
        wait_for_ajaximations

        save_button = f("button[data-testid='save-button']")
        save_button.click
        wait_for_ajaximations

        rule_cards = ff("div[data-testid='allocation-rule-card-wrapper']")
        expect(rule_cards.length).to eq(1)
        expect(rule_cards.first).to include_text(@student1.name)
      end
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

    it "displays the Peer Reviews link in the right-side panel" do
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      wait_for_ajaximations

      expect(f(".assignment_peer_reviews_link")).to be_displayed
    end
  end

  context "peer_reviews page redirect" do
    before(:once) do
      course_with_teacher(active_all: true)
      @course.enable_feature!(:peer_review_allocation_and_grading)
      @course.enable_feature!(:assignments_2_student)
      @assignment = @course.assignments.create!(
        name: "Test Assignment",
        points_possible: 10,
        submission_types: "online_text_entry",
        peer_reviews: true
      )
      @student = student_in_course(course: @course, active_all: true, name: "Student").user
      @assignment.submit_homework(@student, body: "Test submission")
    end

    it "redirects teachers from peer_reviews page to assignment page when FF is enabled" do
      user_session(@teacher)
      get "/courses/#{@course.id}/assignments/#{@assignment.id}/peer_reviews"
      wait_for_ajaximations

      expect(driver.current_url).to include("/courses/#{@course.id}/assignments/#{@assignment.id}")
      expect(driver.current_url).not_to include("/peer_reviews")
    end

    it "redirects TAs from peer_reviews page to assignment page when FF is enabled" do
      ta = user_factory(active_all: true, name: "TA User")
      @course.enroll_ta(ta, enrollment_state: "active")
      user_session(ta)

      get "/courses/#{@course.id}/assignments/#{@assignment.id}/peer_reviews"
      wait_for_ajaximations

      expect(driver.current_url).to include("/courses/#{@course.id}/assignments/#{@assignment.id}")
      expect(driver.current_url).not_to include("/peer_reviews")
    end

    it "does not redirect students from peer_reviews page" do
      user_session(@student)
      get "/courses/#{@course.id}/assignments/#{@assignment.id}/peer_reviews"
      wait_for_ajaximations

      expect(driver.current_url).to include("/peer_reviews")
      expect(f("#content")).to be_displayed
    end

    it "does not redirect instructors when FF is disabled" do
      @course.disable_feature!(:peer_review_allocation_and_grading)
      user_session(@teacher)

      get "/courses/#{@course.id}/assignments/#{@assignment.id}/peer_reviews"
      wait_for_ajaximations

      expect(driver.current_url).to include("/peer_reviews")
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

  context "permissions for TAs and teachers" do
    before(:once) do
      course_with_teacher(active_all: true)
      @course.enable_feature!(:peer_review_allocation_and_grading)
      @assignment = @course.assignments.create!(
        name: "Test Assignment",
        peer_review_count: 2,
        points_possible: 10,
        submission_types: "online_text_entry",
        peer_reviews: true
      )
      @student1 = student_in_course(course: @course, active_all: true, name: "Student 1").user
      @student2 = student_in_course(course: @course, active_all: true, name: "Student 2").user
    end

    context "as a TA with grading permissions but not edit permissions" do
      before(:once) do
        @ta = user_factory(active_all: true, name: "TA User")
        @course.enroll_ta(@ta, enrollment_state: "active")
        role = Role.get_built_in_role("TaEnrollment", root_account_id: @course.root_account.id)
        RoleOverride.create!(
          context: @course.account,
          permission: "manage_assignments_edit",
          role:,
          enabled: false
        )
      end

      before do
        user_session(@ta)
      end

      it "displays the peer review widget" do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        wait_for_ajaximations

        expect(f("#peer-review-assignment-widget-mount-point")).to be_displayed
      end

      it "can view the allocation tray" do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        wait_for_ajaximations

        allocate_button = f("[data-testid='allocate-peer-reviews-button']")
        allocate_button.click
        wait_for_ajaximations

        expect(f("[data-testid='allocation-rules-tray']")).to be_displayed
      end

      it "does not show Add Rule button in allocation tray" do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        wait_for_ajaximations

        allocate_button = f("[data-testid='allocate-peer-reviews-button']")
        allocate_button.click
        wait_for_ajaximations

        expect(f("#content")).not_to contain_css("[data-testid='add-rule-button']")
      end

      it "can view existing allocation rules but not edit or delete them" do
        AllocationRule.create!(
          course: @course,
          assignment: @assignment,
          assessor: @student1,
          assessee: @student2,
          must_review: true,
          review_permitted: true,
          applies_to_assessor: true
        )

        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        wait_for_ajaximations

        allocate_button = f("[data-testid='allocate-peer-reviews-button']")
        allocate_button.click
        wait_for_ajaximations

        rule_cards = ff("div[data-testid='allocation-rule-card-wrapper']")
        expect(rule_cards.length).to eq(1)

        expect(rule_cards.first).not_to contain_css("button[id^='edit-rule-button-']")
        expect(rule_cards.first).not_to contain_css("button[id^='delete-rule-button-']")
      end
    end

    context "as a TA with both grading and edit permissions" do
      before(:once) do
        @ta_with_edit = user_factory(active_all: true, name: "TA With Edit")
        @course.enroll_ta(@ta_with_edit, enrollment_state: "active")
        role = Role.get_built_in_role("TaEnrollment", root_account_id: @course.root_account.id)
        RoleOverride.create!(
          context: @course.account,
          permission: "manage_assignments_edit",
          role:,
          enabled: true
        )
      end

      before do
        user_session(@ta_with_edit)
      end

      it "displays the peer review widget" do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        wait_for_ajaximations

        expect(f("#peer-review-assignment-widget-mount-point")).to be_displayed
      end

      it "can view and use the allocation tray" do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        wait_for_ajaximations

        allocate_button = f("[data-testid='allocate-peer-reviews-button']")
        allocate_button.click
        wait_for_ajaximations

        expect(f("[data-testid='allocation-rules-tray']")).to be_displayed
      end

      it "shows Add Rule button in allocation tray" do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        wait_for_ajaximations

        allocate_button = f("[data-testid='allocate-peer-reviews-button']")
        allocate_button.click
        wait_for_ajaximations

        expect(f("[data-testid='add-rule-button']")).to be_displayed
      end

      it "can create allocation rules" do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        wait_for_ajaximations

        allocate_button = f("[data-testid='allocate-peer-reviews-button']")
        allocate_button.click
        wait_for_ajaximations

        add_rule_button = f("[data-testid='add-rule-button']")
        add_rule_button.click
        wait_for_ajaximations

        expect(f("span[data-testid='create-rule-modal']")).to be_displayed

        target_input = f("input#target-select")
        target_input.send_keys(@student1.name)
        wait_for_ajaximations
        fj("span[role='option']:contains('#{@student1.name}')").click
        wait_for_ajaximations

        subject_input = f("input#subject-select-main")
        subject_input.send_keys(@student2.name)
        wait_for_ajaximations
        fj("span[role='option']:contains('#{@student2.name}')").click
        wait_for_ajaximations

        save_button = f("button[data-testid='save-button']")
        save_button.click
        wait_for_ajaximations

        rule_cards = ff("div[data-testid='allocation-rule-card-wrapper']")
        expect(rule_cards.length).to eq(1)
      end

      it "can edit and delete existing allocation rules" do
        AllocationRule.create!(
          course: @course,
          assignment: @assignment,
          assessor: @student1,
          assessee: @student2,
          must_review: true,
          review_permitted: true,
          applies_to_assessor: true
        )

        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        wait_for_ajaximations

        allocate_button = f("[data-testid='allocate-peer-reviews-button']")
        allocate_button.click
        wait_for_ajaximations

        rule_cards = ff("div[data-testid='allocation-rule-card-wrapper']")
        expect(rule_cards.length).to eq(1)

        expect(f("button[id^='edit-rule-button-']", rule_cards.first)).to be_displayed
        expect(f("button[data-testid='delete-allocation-rule-button']", rule_cards.first)).to be_displayed
      end
    end
  end
end
