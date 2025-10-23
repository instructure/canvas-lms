# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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
require_relative "page_objects/assignment_create_edit_page"
require_relative "page_objects/assignment_page"

describe "assignment" do
  include_context "in-process server selenium tests"

  context "for submission limited attempts" do
    before(:once) do
      @course1 = Course.create!(name: "First Course1")
      @teacher1 = User.create!
      @teacher1 = User.create!(name: "First Teacher")
      @teacher1.accept_terms
      @teacher1.register!
      @course1.enroll_teacher(@teacher1, enrollment_state: "active")
      @assignment1 = @course1.assignments.create!(
        title: "Existing Assignment",
        points_possible: 10,
        submission_types: "online_url,online_upload,online_text_entry"
      )
      @assignment2_paper = @course1.assignments.create!(
        title: "Existing Assignment",
        points_possible: 10,
        submission_types: "on_paper"
      )
    end

    before do
      user_session(@teacher1)
    end

    it "displays the attempts field on edit view" do
      AssignmentCreateEditPage.visit_assignment_edit_page(@course1.id, @assignment1.id)

      expect(AssignmentCreateEditPage.limited_attempts_fieldset.displayed?).to be true
    end

    it "hides attempts field for paper assignment" do
      AssignmentCreateEditPage.visit_assignment_edit_page(@course1.id, @assignment2_paper.id)

      expect(AssignmentCreateEditPage.limited_attempts_fieldset.displayed?).to be false
    end

    it "displays the attempts field on create view" do
      AssignmentCreateEditPage.visit_new_assignment_create_page(@course1.id)
      click_option(AssignmentCreateEditPage.submission_type_selector, "External Tool")

      expect(AssignmentCreateEditPage.limited_attempts_fieldset.displayed?).to be true
    end

    it "hides the attempts field on create view when no submissions is needed" do
      AssignmentCreateEditPage.visit_new_assignment_create_page(@course1.id)
      click_option(AssignmentCreateEditPage.submission_type_selector, "No Submission")

      expect(AssignmentCreateEditPage.limited_attempts_fieldset.displayed?).to be false
    end

    it "allows user to set submission limit", custom_timeout: 25 do
      AssignmentCreateEditPage.visit_assignment_edit_page(@course1.id, @assignment1.id)
      click_option(AssignmentCreateEditPage.limited_attempts_dropdown, "Limited")

      # default attempt count is 1
      expect(AssignmentCreateEditPage.limited_attempts_input.attribute("value")).to eq "1"

      # increase attempts count
      AssignmentCreateEditPage.increase_attempts_btn.click
      AssignmentCreateEditPage.assignment_save_button.click
      wait_for_ajaximations

      expect(AssignmentPage.allowed_attempts_count.text).to include "2"
    end
  end

  context "new quiz" do
    before(:once) do
      Account.site_admin.enable_feature!(:hide_zero_point_quizzes_option)
      course_with_teacher(active_all: true)
      @course.context_external_tools.create! tool_id: ContextExternalTool::QUIZ_LTI,
                                             name: "Q.N",
                                             consumer_key: "1",
                                             shared_secret: "1",
                                             domain: "quizzes.example.com",
                                             url: "http://lti13testtool.docker/launch"
      @new_quiz = @course.assignments.create!(points_possible: 0)
      @new_quiz.quiz_lti!
      @new_quiz.save!
    end

    before do
      user_session(@teacher)
    end

    it "allows user to select option to hide from gradebooks" do
      AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @new_quiz.id)

      expect(AssignmentCreateEditPage.hide_from_gradebooks_checkbox).to be_displayed
    end

    it "when the hide_from_gradebook option is selected the omit from final grade option is automatically selected and disabled" do
      AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @new_quiz.id)
      AssignmentCreateEditPage.hide_from_gradebooks_checkbox.click

      expect(AssignmentCreateEditPage.omit_from_final_grade_checkbox).to be_selected
      expect(AssignmentCreateEditPage.omit_from_final_grade_checkbox).to be_disabled
    end

    it "when the hide_from_gradebook option is deselected the omit from final grade option is automatically enabled and remains selected" do
      AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @new_quiz.id)
      AssignmentCreateEditPage.hide_from_gradebooks_checkbox.click
      AssignmentCreateEditPage.hide_from_gradebooks_checkbox.click

      expect(AssignmentCreateEditPage.omit_from_final_grade_checkbox).to be_selected
      expect(AssignmentCreateEditPage.omit_from_final_grade_checkbox).to be_enabled
    end

    it "when the points possible is edited to greater than 0 hide_from_gradebook option is hidden and the omit from final grade option is automatically enabled and remains selected" do
      AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @new_quiz.id)
      AssignmentCreateEditPage.hide_from_gradebooks_checkbox.click
      AssignmentCreateEditPage.enter_points_possible(10)
      AssignmentCreateEditPage.edit_assignment_name("test") # to get the cursor out of the points input field

      expect(AssignmentCreateEditPage.omit_from_final_grade_checkbox).to be_selected
      expect(AssignmentCreateEditPage.omit_from_final_grade_checkbox).to be_enabled
    end

    it "can be set to be hidden from gradebooks" do
      AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @new_quiz.id)
      AssignmentCreateEditPage.hide_from_gradebooks_checkbox.click
      AssignmentCreateEditPage.save_assignment

      expect(@new_quiz.reload.hide_in_gradebook).to be true
      expect(@new_quiz.reload.omit_from_final_grade).to be true
    end
  end

  describe "for assignments in a course with both mastery paths and course pacing" do
    before(:once) do
      course_with_teacher(active_all: true)
      @course.root_account.enable_feature!(:course_pace_pacing_with_mastery_paths)
      @course.update(
        enable_course_paces: true,
        conditional_release: true
      )

      @assignment = @course.assignments.create!(
        title: "Existing Assignment",
        points_possible: 10,
        submission_types: "online_url,online_upload,online_text_entry"
      )
    end

    before do
      user_session(@teacher)
    end

    it "sets an assignment override for mastery paths when mastery path toggle is turned on" do
      AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @assignment.id)
      AssignmentCreateEditPage.mastery_path_toggle.click
      AssignmentCreateEditPage.save_assignment

      expect(@assignment.assignment_overrides.active.find_by(set_id: AssignmentOverride::NOOP_MASTERY_PATHS, set_type: AssignmentOverride::SET_TYPE_NOOP)).to be_present
    end

    it "removes assignment override for mastery paths when mastery path toggle is turned off" do
      @assignment.assignment_overrides.create(set_id: AssignmentOverride::NOOP_MASTERY_PATHS, set_type: AssignmentOverride::SET_TYPE_NOOP)

      AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @assignment.id)
      AssignmentCreateEditPage.mastery_path_toggle.click
      AssignmentCreateEditPage.save_assignment

      expect(@assignment.assignment_overrides.active.find_by(set_id: AssignmentOverride::NOOP_MASTERY_PATHS, set_type: AssignmentOverride::SET_TYPE_NOOP)).not_to be_present
    end
  end

  context "peer review allocation and grading" do
    before(:once) do
      @pr_course = course_factory(name: "Peer Review Course", active_course: true)
      @pr_course.enable_feature!(:peer_review_grading)
      @pr_course.enable_feature!(:peer_review_allocation)
      @pr_teacher = teacher_in_course(name: "PR Teacher", course: @pr_course, enrollment_state: :active).user
    end

    before do
      user_session(@pr_teacher)
    end

    context "data submission" do
      it "includes peer review data in API call when creating assignment" do
        get "/courses/#{@pr_course.id}/assignments/new"
        wait_for_ajaximations

        f("#assignment_name").send_keys("Peer Review Test Assignment")
        f("#assignment_points_possible").send_keys("10")
        f("#assignment_text_entry").click

        f("[data-testid='peer-review-checkbox'] + label").click
        wait_for_ajaximations

        reviews_required_input = f("input[data-testid='reviews-required-input']")
        reviews_required_input.send_keys([:control, "a"], :backspace, "3")

        points_per_review_input = f("input[data-testid='points-per-review-input']")
        points_per_review_input.send_keys([:control, "a"], :backspace, "5")

        expect_new_page_load { f(".btn-primary[type=submit]").click }
        wait_for_ajaximations

        assignment = @pr_course.assignments.last
        expect(assignment.peer_reviews).to be true
        expect(assignment.peer_review_count).to eq 3
        expect(assignment.peer_review_sub_assignment).not_to be_nil
        expect(assignment.peer_review_sub_assignment.points_possible).to eq 15 # 3 * 5
        expect(assignment.peer_review_sub_assignment.grading_type).to eq "points"
      end

      it "includes peer review sub-assignment with pass_fail grading type" do
        get "/courses/#{@pr_course.id}/assignments/new"
        wait_for_ajaximations

        f("#assignment_name").send_keys("Pass/Fail Peer Review Assignment")
        f("#assignment_text_entry").click
        f("[data-testid='peer-review-checkbox'] + label").click
        wait_for_ajaximations

        fj("button:contains('Advanced Peer Review Configurations')").click
        wait_for_ajaximations

        f("[data-testid='pass-fail-grading-checkbox'] + label").click

        expect_new_page_load { f(".btn-primary[type=submit]").click }
        wait_for_ajaximations

        assignment = @pr_course.assignments.last
        expect(assignment.peer_review_sub_assignment.grading_type).to eq "pass_fail"
      end

      it "includes anonymous peer reviews setting" do
        get "/courses/#{@pr_course.id}/assignments/new"
        wait_for_ajaximations

        f("#assignment_name").send_keys("Anonymous Peer Review Assignment")
        f("#assignment_text_entry").click
        f("[data-testid='peer-review-checkbox'] + label").click
        wait_for_ajaximations

        fj("button:contains('Advanced Peer Review Configurations')").click
        wait_for_ajaximations

        f("[data-testid='anonymity-checkbox'] + label").click

        expect_new_page_load { f(".btn-primary[type=submit]").click }
        wait_for_ajaximations

        assignment = @pr_course.assignments.last
        expect(assignment.anonymous_peer_reviews).to be true
      end

      it "correctly rounds peer review points_possible to avoid floating point precision issues" do
        get "/courses/#{@pr_course.id}/assignments/new"
        wait_for_ajaximations

        f("#assignment_name").send_keys("Floating Point Test Assignment")
        f("#assignment_text_entry").click
        f("[data-testid='peer-review-checkbox'] + label").click
        wait_for_ajaximations

        reviews_required_input = f("input[data-testid='reviews-required-input']")
        reviews_required_input.send_keys([:control, "a"], :backspace, "3")

        points_per_review_input = f("input[data-testid='points-per-review-input']")
        points_per_review_input.send_keys([:control, "a"], :backspace, "1.12")

        # Verify UI shows correctly rounded value
        total_points_display = f("span[data-testid='total-peer-review-points']")
        expect(total_points_display.text).to eq("3.36")

        expect_new_page_load { f(".btn-primary[type=submit]").click }
        wait_for_ajaximations

        assignment = @pr_course.assignments.last
        peer_review_sub = assignment.peer_review_sub_assignment

        # Verify backend stores correctly rounded value: 3.36, not 3.3600000000000003
        expect(peer_review_sub.points_possible).to eq 3.36
      end
    end

    context "data loading from existing assignment" do
      before(:once) do
        @pr_assignment = @pr_course.assignments.create!(
          name: "Existing Peer Review Assignment",
          points_possible: 10,
          submission_types: "online_text_entry",
          peer_reviews: true,
          peer_review_count: 5
        )

        @peer_review_sub = PeerReview::PeerReviewCreatorService.call(
          parent_assignment: @pr_assignment,
          points_possible: 25, # 5 reviews * 5 points each
          grading_type: "points"
        )
      end

      it "loads existing peer review configuration when editing" do
        get "/courses/#{@pr_course.id}/assignments/#{@pr_assignment.id}/edit"
        wait_for_ajaximations

        expect(f("[data-testid='peer-review-checkbox']")).to be_checked

        reviews_required_input = f("input[data-testid='reviews-required-input']")
        expect(reviews_required_input.attribute("value")).to eq("5")

        # Verify points per review is calculated correctly (25 / 5 = 5)
        points_per_review_input = f("input[data-testid='points-per-review-input']")
        expect(points_per_review_input.attribute("value")).to eq("5")

        total_points_display = f("span[data-testid='total-peer-review-points']")
        expect(total_points_display.text).to eq("25")
      end

      it "updates peer review configuration when editing" do
        get "/courses/#{@pr_course.id}/assignments/#{@pr_assignment.id}/edit"
        wait_for_ajaximations

        reviews_required_input = f("input[data-testid='reviews-required-input']")
        reviews_required_input.send_keys([:control, "a"], :backspace, "4")

        points_per_review_input = f("input[data-testid='points-per-review-input']")
        points_per_review_input.send_keys([:control, "a"], :backspace, "6")

        expect_new_page_load { f(".btn-primary[type=submit]").click }
        wait_for_ajaximations

        @pr_assignment.reload
        @peer_review_sub.reload
        expect(@pr_assignment.peer_review_count).to eq 4
        expect(@peer_review_sub.points_possible).to eq 24 # 4 * 6
      end

      it "loads the initial value of submission required when editing an assignment", custom_timeout: 30 do
        @pr_assignment.update!(peer_review_submission_required: true)

        get "/courses/#{@pr_course.id}/assignments/#{@pr_assignment.id}/edit"
        wait_for_ajaximations

        fj("button:contains('Advanced Peer Review Configurations')").click
        wait_for_ajaximations

        submission_required_checkbox = f("#peer_reviews_submission_required_checkbox")
        expect(submission_required_checkbox).to be_selected
      end

      it "allows toggling submission required and persists the value", custom_timeout: 40 do
        get "/courses/#{@pr_course.id}/assignments/#{@pr_assignment.id}/edit"
        wait_for_ajaximations

        fj("button:contains('Advanced Peer Review Configurations')").click
        wait_for_ajaximations

        submission_required_checkbox = f("#peer_reviews_submission_required_checkbox")
        expect(submission_required_checkbox).to be_selected

        f("[data-testid='submission-required-checkbox'] + label").click
        expect(submission_required_checkbox).not_to be_selected

        find_button("Save").click
        wait_for_ajaximations

        expect(@pr_assignment.reload.peer_review_submission_required).to be false

        get "/courses/#{@pr_course.id}/assignments/#{@pr_assignment.id}/edit"
        wait_for_ajaximations

        fj("button:contains('Advanced Peer Review Configurations')").click
        wait_for_ajaximations

        submission_required_checkbox = f("#peer_reviews_submission_required_checkbox")
        expect(submission_required_checkbox).not_to be_selected

        f("[data-testid='submission-required-checkbox'] + label").click
        expect(submission_required_checkbox).to be_selected

        find_button("Save").click
        wait_for_ajaximations

        expect(@pr_assignment.reload.peer_review_submission_required).to be true
      end

      it "preserves toggle values when updating assignment with Advanced Configuration collapsed", custom_timeout: 60 do
        # Create a group category for testing within-groups toggle
        group_category = @pr_course.group_categories.create!(name: "Test Group Category")

        get "/courses/#{@pr_course.id}/assignments/new"
        wait_for_ajaximations

        f("#assignment_name").send_keys("Peer Review Assignment with Toggles")
        f("#assignment_text_entry").click

        # Set up as group assignment
        f("#has_group_category").click
        click_option("#assignment_group_category_id", group_category.name)

        f("[data-testid='peer-review-checkbox'] + label").click
        wait_for_ajaximations

        reviews_required_input = f("input[data-testid='reviews-required-input']")
        reviews_required_input.send_keys([:control, "a"], :backspace, "2")

        points_per_review_input = f("input[data-testid='points-per-review-input']")
        points_per_review_input.send_keys([:control, "a"], :backspace, "5")

        fj("button:contains('Advanced Peer Review Configurations')").click
        wait_for_ajaximations

        f("[data-testid='within-groups-checkbox'] + label").click
        f("[data-testid='pass-fail-grading-checkbox'] + label").click
        f("[data-testid='anonymity-checkbox'] + label").click
        f("[data-testid='submission-required-checkbox'] + label").click

        expect_new_page_load { f(".btn-primary[type=submit]").click }
        wait_for_ajaximations

        assignment = @pr_course.assignments.last
        expect(assignment.intra_group_peer_reviews).to be true
        expect(assignment.anonymous_peer_reviews).to be true
        expect(assignment.peer_review_submission_required).to be true

        peer_review_sub = assignment.peer_review_sub_assignment
        expect(peer_review_sub.grading_type).to eq "pass_fail"

        # Edit assignment with Advanced Configuration COLLAPSED
        get "/courses/#{@pr_course.id}/assignments/#{assignment.id}/edit"
        wait_for_ajaximations

        find_button("Save").click
        wait_for_ajaximations

        # Verify all toggles are still enabled after update
        assignment.reload
        expect(assignment.intra_group_peer_reviews).to be true
        expect(assignment.anonymous_peer_reviews).to be true
        expect(assignment.peer_review_submission_required).to be true

        peer_review_sub.reload
        expect(peer_review_sub.grading_type).to eq "pass_fail"
      end
    end

    context "error handling" do
      it "displays flash alert for peer review backend errors" do
        get "/courses/#{@pr_course.id}/assignments/new"
        wait_for_ajaximations

        f("#assignment_name").send_keys("Test Assignment")
        f("#assignment_text_entry").click
        f("[data-testid='peer-review-checkbox'] + label").click
        wait_for_ajaximations

        # rubocop:disable Specs/NoExecuteScript
        driver.execute_script(<<~JS)
          jQuery.ajax = function(options) {
            if (options.url && options.url.includes('/assignments')) {
              const xhr = { responseJSON: { errors: 'Failed to create or update peer review sub assignment' } }
              if (options.error) options.error(xhr)
              return jQuery.Deferred().reject(xhr).promise()
            }
          }
        JS
        # rubocop:enable Specs/NoExecuteScript

        f(".btn-primary[type=submit]").click
        wait_for_ajaximations
        expect(fj("span:contains('Failed to create or update peer review sub assignment')")).to be_present
      end
    end

    context "toggle and field reset" do
      it "resets all peer review fields and toggles to defaults when peer review is disabled then re-enabled", custom_timeout: 30 do
        # Create a group category for testing within-groups toggle
        group_category = @pr_course.group_categories.create!(name: "Test Group Category")

        get "/courses/#{@pr_course.id}/assignments/new"
        wait_for_ajaximations

        f("#assignment_name").send_keys("Toggle Reset Test Assignment")
        f("#assignment_text_entry").click

        # Set up as group assignment
        f("#has_group_category").click
        click_option("#assignment_group_category_id", group_category.name)

        f("[data-testid='peer-review-checkbox'] + label").click
        wait_for_ajaximations

        reviews_required_input = f("input[data-testid='reviews-required-input']")
        reviews_required_input.send_keys([:control, "a"], :backspace, "5")

        points_per_review_input = f("input[data-testid='points-per-review-input']")
        points_per_review_input.send_keys([:control, "a"], :backspace, "10")

        total_points_display = f("span[data-testid='total-peer-review-points']")
        expect(total_points_display.text).to eq("50")

        fj("button:contains('Advanced Peer Review Configurations')").click
        wait_for_ajaximations

        f("[data-testid='within-groups-checkbox'] + label").click
        f("[data-testid='pass-fail-grading-checkbox'] + label").click
        f("[data-testid='anonymity-checkbox'] + label").click
        f("[data-testid='submission-required-checkbox'] + label").click

        expect_new_page_load { f(".btn-primary[type=submit]").click }
        wait_for_ajaximations

        assignment = @pr_course.assignments.last

        # Verify assignment was created with custom values
        expect(assignment.peer_reviews).to be true
        expect(assignment.peer_review_count).to eq 5
        expect(assignment.peer_review_sub_assignment.points_possible).to eq 50
        expect(assignment.intra_group_peer_reviews).to be true
        expect(assignment.peer_review_sub_assignment.grading_type).to eq "pass_fail"
        expect(assignment.anonymous_peer_reviews).to be true
        expect(assignment.peer_review_submission_required).to be true

        get "/courses/#{@pr_course.id}/assignments/#{assignment.id}/edit"
        wait_for_ajaximations

        f("[data-testid='peer-review-checkbox'] + label").click
        wait_for_ajaximations

        find_button("Save").click
        wait_for_ajaximations

        # Edit assignment again and re-enable peer reviews
        get "/courses/#{@pr_course.id}/assignments/#{assignment.id}/edit"
        wait_for_ajaximations

        f("[data-testid='peer-review-checkbox'] + label").click
        wait_for_ajaximations

        # Verify numeric fields are reset to defaults
        reviews_required_input = f("input[data-testid='reviews-required-input']")
        expect(reviews_required_input.attribute("value")).to eq("1")

        points_per_review_input = f("input[data-testid='points-per-review-input']")
        expect(points_per_review_input.attribute("value")).to eq("0")

        total_points_display = f("span[data-testid='total-peer-review-points']")
        expect(total_points_display.text).to eq("0")

        fj("button:contains('Advanced Peer Review Configurations')").click
        wait_for_ajaximations

        # Verify all toggles are disabled (default state)
        within_groups_checkbox = f("#peer_reviews_within_groups_checkbox")
        expect(within_groups_checkbox).not_to be_selected

        pass_fail_checkbox = f("#peer_reviews_pass_fail_grading_checkbox")
        expect(pass_fail_checkbox).not_to be_selected

        anonymity_checkbox = f("#peer_reviews_anonymity_checkbox")
        expect(anonymity_checkbox).not_to be_selected

        submission_required_checkbox = f("#peer_reviews_submission_required_checkbox")
        expect(submission_required_checkbox).not_to be_selected
      end

      it "resets all peer review settings when peer reviews are disabled", custom_timeout: 30 do
        pr_assignment = @pr_course.assignments.create!(
          name: "Test Assignment with Peer Reviews",
          points_possible: 10,
          submission_types: "online_text_entry",
          peer_reviews: true,
          peer_review_count: 3,
          anonymous_peer_reviews: true,
          intra_group_peer_reviews: true,
          peer_review_submission_required: true
        )

        get "/courses/#{@pr_course.id}/assignments/#{pr_assignment.id}/edit"
        wait_for_ajaximations

        peer_review_checkbox = f("[data-testid='peer-review-checkbox']")
        expect(peer_review_checkbox).to be_checked

        # Uncheck peer reviews
        f("[data-testid='peer-review-checkbox'] + label").click
        wait_for_ajaximations

        expect_new_page_load { f(".btn-primary[type=submit]").click }
        wait_for_ajaximations

        # Verify all peer review fields are reset
        pr_assignment.reload
        expect(pr_assignment.peer_reviews).to be false
        expect(pr_assignment.peer_review_count).to eq 0
        expect(pr_assignment.anonymous_peer_reviews).to be false
        expect(pr_assignment.intra_group_peer_reviews).to be false
        expect(pr_assignment.peer_review_submission_required).to be false
      end

      it "resets intra_group_peer_reviews when assignment changes from group to non-group", custom_timeout: 30 do
        # Create assignment as group assignment with within-groups peer reviews
        group_category = @pr_course.group_categories.create!(name: "Test Group Category")
        pr_assignment = @pr_course.assignments.create!(
          name: "Group Assignment with Peer Reviews",
          points_possible: 10,
          submission_types: "online_text_entry",
          peer_reviews: true,
          peer_review_count: 2,
          group_category_id: group_category.id,
          intra_group_peer_reviews: true
        )

        get "/courses/#{@pr_course.id}/assignments/#{pr_assignment.id}/edit"
        wait_for_ajaximations

        # uncheck group assignment checkbox
        group_assignment_checkbox = f("#has_group_category")
        group_assignment_checkbox.click

        expect_new_page_load { f(".btn-primary[type=submit]").click }
        wait_for_ajaximations

        pr_assignment.reload
        expect(pr_assignment.peer_reviews).to be true
        expect(pr_assignment.group_category_id).to be_nil
        expect(pr_assignment.intra_group_peer_reviews).to be false
      end
    end
  end

  context "peer review with only allocation enabled" do
    before(:once) do
      @allocation_course = course_factory(name: "Allocation Only Course", active_course: true)
      @allocation_course.enable_feature!(:peer_review_allocation)
      @allocation_course.disable_feature!(:peer_review_grading)
      @allocation_teacher = teacher_in_course(name: "Allocation Teacher", course: @allocation_course, enrollment_state: :active).user
    end

    before do
      user_session(@allocation_teacher)
    end

    context "data loading from existing assignment" do
      before(:once) do
        # Create a group category for testing within-groups toggle
        @allocation_group_category = @allocation_course.group_categories.create!(name: "Allocation Group Category")

        @allocation_assignment = @allocation_course.assignments.create!(
          name: "Allocation Only Assignment",
          points_possible: 10,
          submission_types: "online_text_entry",
          peer_reviews: true,
          peer_review_count: 3,
          intra_group_peer_reviews: true,
          anonymous_peer_reviews: true,
          peer_review_submission_required: true,
          group_category: @allocation_group_category
        )
      end

      it "loads peer_review_count correctly from database" do
        get "/courses/#{@allocation_course.id}/assignments/#{@allocation_assignment.id}/edit"
        wait_for_ajaximations

        expect(f("[data-testid='peer-review-checkbox']")).to be_checked

        reviews_required_input = f("input[data-testid='reviews-required-input']")
        expect(reviews_required_input.attribute("value")).to eq("3")
      end

      it "shows allocation-specific fields" do
        get "/courses/#{@allocation_course.id}/assignments/#{@allocation_assignment.id}/edit"
        wait_for_ajaximations

        fj("button:contains('Advanced Peer Review Configurations')").click
        wait_for_ajaximations

        within_groups_checkbox = f("#peer_reviews_within_groups_checkbox")
        expect(within_groups_checkbox).to be_displayed
        expect(within_groups_checkbox).to be_selected

        anonymity_checkbox = f("#peer_reviews_anonymity_checkbox")
        expect(anonymity_checkbox).to be_displayed
        expect(anonymity_checkbox).to be_selected

        submission_required_checkbox = f("#peer_reviews_submission_required_checkbox")
        expect(submission_required_checkbox).to be_displayed
        expect(submission_required_checkbox).to be_selected
      end
    end
  end

  context "peer review with only grading enabled" do
    before(:once) do
      @grading_course = course_factory(name: "Grading Only Course", active_course: true)
      @grading_course.disable_feature!(:peer_review_allocation)
      @grading_course.enable_feature!(:peer_review_grading)
      @grading_teacher = teacher_in_course(name: "Grading Teacher", course: @grading_course, enrollment_state: :active).user
    end

    before do
      user_session(@grading_teacher)
    end

    context "data loading from existing assignment" do
      before(:once) do
        @grading_assignment = @grading_course.assignments.create!(
          name: "Grading Only Assignment",
          points_possible: 10,
          submission_types: "online_text_entry",
          peer_reviews: true,
          peer_review_count: 3
        )

        @grading_peer_review_sub = PeerReview::PeerReviewCreatorService.call(
          parent_assignment: @grading_assignment,
          points_possible: 15, # 3 reviews * 5 points each
          grading_type: "points"
        )
      end

      it "loads peer_review_count correctly from database" do
        get "/courses/#{@grading_course.id}/assignments/#{@grading_assignment.id}/edit"
        wait_for_ajaximations

        expect(f("[data-testid='peer-review-checkbox']")).to be_checked

        reviews_required_input = f("input[data-testid='reviews-required-input']")
        expect(reviews_required_input.attribute("value")).to eq("3")
      end

      it "shows grading-specific fields with correct values" do
        get "/courses/#{@grading_course.id}/assignments/#{@grading_assignment.id}/edit"
        wait_for_ajaximations

        expect(f("[data-testid='peer-review-checkbox']")).to be_checked

        reviews_required_input = f("input[data-testid='reviews-required-input']")
        expect(reviews_required_input.attribute("value")).to eq("3")

        # Points per review should be calculated: 15 / 3 = 5
        points_per_review_input = f("input[data-testid='points-per-review-input']")
        expect(points_per_review_input.attribute("value")).to eq("5")

        total_points_display = f("span[data-testid='total-peer-review-points']")
        expect(total_points_display.text).to eq("15")
      end

      it "shows grading toggle in advanced settings" do
        get "/courses/#{@grading_course.id}/assignments/#{@grading_assignment.id}/edit"
        wait_for_ajaximations

        fj("button:contains('Advanced Peer Review Configurations')").click
        wait_for_ajaximations

        pass_fail_checkbox = f("[data-testid='pass-fail-grading-checkbox']")
        expect(pass_fail_checkbox).to be_displayed
        expect(pass_fail_checkbox).not_to be_selected
      end
    end
  end

  describe "peer review across sections" do
    before(:once) do
      course_with_teacher(active_all: true)
      @course.enable_feature!(:peer_review_allocation)
      @assignment = @course.assignments.create!(
        title: "Peer Review Assignment",
        points_possible: 10,
        submission_types: "online_text_entry",
        peer_reviews: true
      )
    end

    before do
      user_session(@teacher)
    end

    it "loads the initial value of allow across sections when editing an assignment", custom_timeout: 30 do
      @assignment.update!(peer_review_across_sections: false)

      get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
      wait_for_ajaximations

      fj("button:contains('Advanced Peer Review Configurations')").click
      wait_for_ajaximations

      across_sections_checkbox = f("#peer_reviews_across_sections_checkbox")
      expect(across_sections_checkbox).not_to be_selected
    end

    it "allows toggling allow across sections and persists the value", custom_timeout: 40 do
      get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
      wait_for_ajaximations

      fj("button:contains('Advanced Peer Review Configurations')").click
      wait_for_ajaximations

      f("[data-testid='across-sections-checkbox'] + label").click

      find_button("Save").click
      wait_for_ajaximations

      expect(@assignment.reload.peer_review_across_sections).to be false

      get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
      wait_for_ajaximations

      fj("button:contains('Advanced Peer Review Configurations')").click
      wait_for_ajaximations

      f("[data-testid='across-sections-checkbox'] + label").click

      find_button("Save").click
      wait_for_ajaximations

      expect(@assignment.reload.peer_review_across_sections).to be true
    end

    it "persists disabled state after collapsing Advanced Configuration section", custom_timeout: 40 do
      get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
      wait_for_ajaximations

      fj("button:contains('Advanced Peer Review Configurations')").click
      wait_for_ajaximations

      f("[data-testid='across-sections-checkbox'] + label").click

      # Collapse the Advanced Configuration section
      fj("button:contains('Advanced Peer Review Configurations')").click
      wait_for_ajaximations

      find_button("Save").click
      wait_for_ajaximations

      expect(@assignment.reload.peer_review_across_sections).to be false
    end
  end
end
