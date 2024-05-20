# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
require_relative "../helpers/public_courses_context"
require_relative "../helpers/files_common"
require_relative "../helpers/admin_settings_common"
require_relative "../../helpers/k5_common"

describe "assignments" do
  include_context "in-process server selenium tests"
  include FilesCommon
  include AssignmentsCommon
  include AdminSettingsCommon
  include CustomScreenActions
  include CustomSeleniumActions
  include K5Common

  # NOTE: due date testing can be found in assignments_overrides_spec

  context "as a teacher" do
    before(:once) do
      @teacher = user_with_pseudonym
      course_with_teacher({ user: @teacher, active_course: true, active_enrollment: true })
      @course.start_at = nil
      @course.save!
      @course.require_assignment_group
    end

    before do
      create_session(@pseudonym)
    end

    describe "keyboard shortcuts" do
      context "when the user has keyboard shortcuts enabled" do
        before do
          get "/courses/#{@course.id}/assignments"
        end

        it 'keyboard shortcut "SHIFT-?"' do
          driver.action.key_down(:shift).key_down("?").key_up(:shift).key_up("?").perform
          keyboard_nav = f("#keyboard_navigation")
          expect(keyboard_nav).to be_displayed
        end
      end

      context "when the user has keyboard shortcuts disabled" do
        before do
          @teacher.enable_feature!(:disable_keyboard_shortcuts)
          get "/courses/#{@course.id}/assignments"
        end

        it "keyboard shortcut dialog is not accesible when user disables keyboard shortcuts" do
          driver.action.key_down(:shift).key_down("?").key_up(:shift).key_up("?").perform
          keyboard_nav = f("#keyboard_navigation")
          expect(keyboard_nav).not_to be_displayed
        end
      end
    end

    context "save and publish button" do
      def create_assignment(publish = true, params = { name: "Test Assignment" })
        @assignment = @course.assignments.create(params)
        @assignment.unpublish unless publish
        get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
      end

      it "can save and publish an assignment", priority: "1" do
        create_assignment false

        expect(f("#assignment-draft-state")).to be_displayed

        expect_new_page_load { f(".save_and_publish").click }
        expect(f("#assignment_publish_button.btn-published")).to be_displayed

        # Check that the list of quizzes is also updated
        get "/courses/#{@course.id}/assignments"
        expect(f("#assignment_#{@assignment.id} .icon-publish")).to be_displayed
      end

      it "does not exist in a published assignment", priority: "1" do
        create_assignment

        expect(f("#content")).not_to contain_css(".save_and_publish")
      end

      context "moderated grading assignments" do
        before do
          @assignment = @course.assignments.create({ name: "Test Moderated Assignment" })
          @assignment.update_attribute(:moderated_grading, true)
          @assignment.update_attribute(:grader_count, 1)
          @assignment.update_attribute(:final_grader, @teacher)
          @assignment.unpublish
        end

        it "shows the moderate button when the assignment is published", priority: "1" do
          get "/courses/#{@course.id}/assignments/#{@assignment.id}"
          f("#assignment_publish_button").click
          wait_for_ajaximations
          expect(f("#moderated_grading_button")).to be_displayed
        end

        it "removes the moderate button when the assignment is unpublished", priority: "1" do
          @assignment.publish
          get "/courses/#{@course.id}/assignments/#{@assignment.id}"
          f("#assignment_publish_button").click
          wait_for_ajaximations
          expect(f("#moderated_grading_button")).not_to be_displayed
        end
      end
    end

    it "shows speed grader link when published" do
      @assignment = @course.assignments.create({ name: "Test Moderated Assignment" })
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      expect(f("#speed-grader-link-container")).to be_present
    end

    it "hides speed grader link when unpublished" do
      @assignment = @course.assignments.create({ name: "Test Moderated Assignment" })
      @assignment.unpublish
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      expect(f("#speed-grader-link-container").attribute("class")).to include("hidden")
    end

    context "archived grading schemes enabled" do
      before do
        Account.site_admin.enable_feature!(:grading_scheme_updates)
        Account.site_admin.enable_feature!(:archived_grading_schemes)
        @account = @course.account
        @active_grading_standard = @course.grading_standards.create!(title: "Active Grading Scheme", data: { "A" => 0.9, "F" => 0 }, scaling_factor: 1.0, points_based: false, workflow_state: "active")
        @archived_grading_standard = @course.grading_standards.create!(title: "Archived Grading Scheme", data: { "A" => 0.9, "F" => 0 }, scaling_factor: 1.0, points_based: false, workflow_state: "archived")
        @account_grading_standard = @account.grading_standards.create!(title: "Account Grading Scheme", data: { "A" => 0.9, "F" => 0 }, scaling_factor: 1.0, points_based: false, workflow_state: "active")
        assignment_name = "first test assignment"
        due_date = Time.now.utc + 2.days
        group = @course.assignment_groups.create!(name: "default")
        @course.assignment_groups.create!(name: "second default")
        @assignment = @course.assignments.create!(
          name: assignment_name,
          due_at: due_date,
          assignment_group: group,
          unlock_at: due_date - 1.day,
          grading_type: "letter_grade"
        )
      end

      it "shows archived grading scheme if it is the course default twice, once to follow course default scheme and once to choose that scheme to use" do
        @course.update!(grading_standard_id: @archived_grading_standard.id)
        @course.reload
        get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
        wait_for_ajaximations
        expect(f("[data-testid='grading-schemes-selector-dropdown']").attribute("title")).to eq(@archived_grading_standard.title + " (course default)")
        f("[data-testid='grading-schemes-selector-dropdown']").click
        expect(f("[data-testid='grading-schemes-selector-option-#{@course.grading_standard.id}']")).to include_text(@course.grading_standard.title)
      end

      it "shows archived grading scheme if it is the current assignment grading standard" do
        @assignment.update!(grading_standard_id: @archived_grading_standard.id)
        @assignment.reload
        get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
        wait_for_ajaximations
        expect(f("[data-testid='grading-schemes-selector-dropdown']").attribute("title")).to eq(@archived_grading_standard.title)
      end

      it "removes grading schemes from dropdown after archiving them but still shows them upon reopening the modal" do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
        wait_for_ajaximations
        f("[data-testid='grading-schemes-selector-dropdown']").click
        expect(f("[data-testid='grading-schemes-selector-option-#{@active_grading_standard.id}']")).to be_present
        f("[data-testid='manage-all-grading-schemes-button']").click
        wait_for_ajaximations
        f("[data-testid='grading-scheme-#{@active_grading_standard.id}-archive-button']").click
        wait_for_ajaximations
        f("[data-testid='manage-all-grading-schemes-close-button']").click
        wait_for_ajaximations
        f("[data-testid='grading-schemes-selector-dropdown']").click
        expect(f("[data-testid='grading-schemes-selector-dropdown-form']")).not_to contain_css("[data-testid='grading-schemes-selector-option-#{@active_grading_standard.id}']")
        f("[data-testid='manage-all-grading-schemes-button']").click
        wait_for_ajaximations
        expect(f("[data-testid='grading-scheme-row-#{@active_grading_standard.id}']").text).to be_present
      end

      it "shows all archived schemes in the manage grading schemes modal" do
        archived_gs1 = @course.grading_standards.create!(title: "Archived Grading Scheme 1", data: { "A" => 0.9, "F" => 0 }, scaling_factor: 1.0, points_based: false, workflow_state: "archived")
        archived_gs2 = @course.grading_standards.create!(title: "Archived Grading Scheme 2", data: { "A" => 0.9, "F" => 0 }, scaling_factor: 1.0, points_based: false, workflow_state: "archived")
        archived_gs3 = @course.grading_standards.create!(title: "Archived Grading Scheme 3", data: { "A" => 0.9, "F" => 0 }, scaling_factor: 1.0, points_based: false, workflow_state: "archived")
        get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
        wait_for_ajaximations
        f("[data-testid='manage-all-grading-schemes-button']").click
        wait_for_ajaximations
        expect(f("[data-testid='grading-scheme-#{archived_gs1.id}-name']")).to include_text(archived_gs1.title)
        expect(f("[data-testid='grading-scheme-#{archived_gs2.id}-name']")).to include_text(archived_gs2.title)
        expect(f("[data-testid='grading-scheme-#{archived_gs3.id}-name']")).to include_text(archived_gs3.title)
      end

      it "will still show the assignment grading scheme if you archive it on the edit page in the management modal and persist on reload" do
        @assignment.update!(grading_standard_id: @active_grading_standard.id)
        @assignment.reload
        get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
        wait_for_ajaximations
        expect(f("[data-testid='grading-schemes-selector-dropdown']").attribute("title")).to eq(@active_grading_standard.title)
        f("[data-testid='manage-all-grading-schemes-button']").click
        wait_for_ajaximations
        f("[data-testid='grading-scheme-#{@active_grading_standard.id}-archive-button']").click
        wait_for_ajaximations
        f("[data-testid='manage-all-grading-schemes-close-button']").click
        wait_for_ajaximations
        expect(f("[data-testid='grading-schemes-selector-dropdown']").attribute("title")).to eq(@active_grading_standard.title)
        get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
        wait_for_ajaximations
        expect(f("[data-testid='grading-schemes-selector-dropdown']").attribute("title")).to eq(@active_grading_standard.title)
      end
    end

    it "edits an assignment", priority: "1" do
      assignment_name = "first test assignment"
      due_date = Time.now.utc + 2.days
      group = @course.assignment_groups.create!(name: "default")
      second_group = @course.assignment_groups.create!(name: "second default")
      @assignment = @course.assignments.create!(
        name: assignment_name,
        due_at: due_date,
        assignment_group: group,
        unlock_at: due_date - 1.day
      )

      get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
      wait_for_ajaximations

      expect(f("#assignment_group_id")).to be_displayed
      click_option("#assignment_group_id", second_group.name)
      click_option("#assignment_grading_type", "Letter Grade")

      # check grading levels dialog
      f(".edit_letter_grades_link").click
      wait_for_ajaximations
      expect(f("#edit_letter_grades_form")).to be_displayed
      close_visible_dialog

      # check peer reviews option
      form = f("#edit_assignment_form")
      assignment_points_possible = f("#assignment_points_possible")
      replace_content(assignment_points_possible, "5")
      form.find_element(:css, "#assignment_peer_reviews").click
      wait_for_ajaximations
      form.find_element(:css, "#assignment_automatic_peer_reviews").click
      wait_for_ajaximations
      f("#assignment_peer_review_count").send_keys("2")
      driver.execute_script "$('#assignment_peer_reviews_assign_at + .ui-datepicker-trigger').click()"
      wait_for_ajaximations
      datepicker = datepicker_next
      datepicker.find_element(:css, ".ui-datepicker-ok").click
      wait_for_ajaximations
      f("#assignment_name").send_keys(" edit")

      # save changes
      submit_assignment_form
      expect(driver.title).to include(assignment_name + " edit")
    end

    # EVAL-3711 Remove this test when instui_nav feature flag is removed
    it "creates an assignment using main add button", :xbrowser, priority: "1" do
      assignment_name = "first assignment"
      # freeze for a certain time, so we don't get unexpected ui complications
      time = DateTime.new(Time.now.year, 1, 7, 2, 13)
      Timecop.freeze(time) do
        due_at = format_time_for_view(time)

        get "/courses/#{@course.id}/assignments"
        # create assignment
        wait_for_new_page_load { f(".new_assignment").click }
        f("#assignment_name").send_keys(assignment_name)
        replace_content(f("#assignment_points_possible"), "10")
        click_option("#assignment_submission_type", "Online")
        ["#assignment_text_entry", "#assignment_online_url", "#assignment_online_upload"].each do |element|
          f(element).click
        end
        replace_content(f(".DueDateInput"), due_at)

        submit_assignment_form
        wait_for_ajaximations
        # confirm all our settings were saved and are now displayed
        expect(f("h1.title")).to include_text(assignment_name)
        expect(f("#assignment_show .points_possible")).to include_text("10")
        expect(f("#assignment_show fieldset")).to include_text("a text entry box, a website url, or a file upload")

        expect(f(".assignment_dates")).to include_text(due_at)
      end
    end

    it "creates an assignment using main add button with the instui nav feature flag on", :xbrowser, priority: "1" do
      @course.root_account.enable_feature!(:instui_nav)
      assignment_name = "first assignment"
      # freeze for a certain time, so we don't get unexpected ui complications
      time = DateTime.new(Time.now.year, 1, 7, 2, 13)
      Timecop.freeze(time) do
        due_at = format_time_for_view(time)

        get "/courses/#{@course.id}/assignments"
        # create assignment
        wait_for_new_page_load { f("[data-testid='new_assignment_button']").click }
        f("#assignment_name").send_keys(assignment_name)
        replace_content(f("#assignment_points_possible"), "10")
        click_option("#assignment_submission_type", "Online")
        ["#assignment_text_entry", "#assignment_online_url", "#assignment_online_upload"].each do |element|
          f(element).click
        end
        replace_content(f(".DueDateInput"), due_at)

        submit_assignment_form
        wait_for_ajaximations
        # confirm all our settings were saved and are now displayed
        expect(f("h1.title")).to include_text(assignment_name)
        expect(f("#assignment_show .points_possible")).to include_text("10")
        expect(f("#assignment_show fieldset")).to include_text("a text entry box, a website url, or a file upload")

        expect(f(".assignment_dates")).to include_text(due_at)
      end
    end

    it "only allows an assignment editor to edit points and title if assignment has multiple due dates" do
      middle_number = "15"
      expected_date = (Time.now - 1.month).strftime("%b #{middle_number}")
      @assignment = @course.assignments.create!(
        title: "VDD Test Assignment",
        due_at: expected_date
      )
      section = @course.course_sections.create!(name: "new section")
      @assignment.assignment_overrides.create! do |override|
        override.set = section
        override.title = "All"
        override.due_at = 1.day.ago
        override.due_at_overridden = true
      end
      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations
      fj("#assign_#{@assignment.id}_manage_link").click
      wait_for_ajaximations
      f("#assignment_#{@assignment.id} .edit_assignment").click
      expect(f("#content")).not_to contain_jqcss(".form-dialog .ui-datepicker-trigger:visible")
      # be_disabled
      expect(f(".multiple_due_dates input")).to be_disabled
      assignment_title = f("#assign_#{@assignment.id}_assignment_name")
      assignment_points_possible = f("#assign_#{@assignment.id}_assignment_points")
      replace_content(assignment_title, "VDD Test Assignment Updated")
      replace_content(assignment_points_possible, "100")
      submit_form(fj(".form-dialog:visible"))
      wait_for_ajaximations
      expect(@assignment.reload.points_possible).to eq 100
      expect(@assignment.title).to eq "VDD Test Assignment Updated"
      # Assert the time didn't change
      expect(@assignment.due_at.strftime("%b %d")).to eq expected_date
    end

    it "creates a simple assignment and defaults post_to_sis" do
      a = @course.account
      a.settings[:sis_default_grade_export] = { locked: false, value: true }
      a.save!
      assignment_name = "test_assignment_thing_#{rand(10_000)}"
      get "/courses/#{@course.id}/assignments"
      group = @course.assignment_groups.first
      f(".add_assignment").click
      replace_content(f("#ag_#{group.id}_assignment_name"), assignment_name)
      f(".create_assignment").click
      wait_for_ajaximations
      assignment = @course.assignments.where(title: assignment_name).last
      expect(assignment).not_to be_nil
      expect(assignment).to be_post_to_sis
    end

    it "creates an assignment with more options", priority: "2" do
      enable_cache do
        expected_text = "Assignment 1"
        # freeze time to avoid ui complications
        time = DateTime.new(2015, 1, 7, 2, 13)
        Timecop.freeze(time) do
          due_at = format_time_for_datepicker(time)
          points = "25"

          get "/courses/#{@course.id}/assignments"
          group = @course.assignment_groups.first
          AssignmentGroup.where(id: group).update_all(updated_at: 1.hour.ago)
          first_stamp = group.reload.updated_at.to_i
          f(".add_assignment").click
          wait_for_ajaximations
          replace_content(f("#ag_#{group.id}_assignment_name"), expected_text)
          replace_content(f("#ag_#{group.id}_assignment_due_at"), due_at)
          replace_content(f("#ag_#{group.id}_assignment_points"), points)
          expect_new_page_load { f(".more_options").click }
          expect(f("#assignment_name").attribute(:value)).to include(expected_text)
          expect(f("#assignment_points_possible").attribute(:value)).to include(points)
          due_at_field = fj(".date_field[data-date-type='due_at']:first")
          expect(due_at_field).to have_value due_at
          click_option("#assignment_submission_type", "No Submission")
          submit_assignment_form
          expect(@course.assignments.count).to eq 1
          get "/courses/#{@course.id}/assignments"
          expect(f(".assignment")).to include_text(expected_text)
          group.reload
          expect(group.updated_at.to_i).not_to eq first_stamp
        end
      end
    end

    it "keeps erased field on more options click", priority: "2" do
      enable_cache do
        middle_number = "15"
        expected_date = (Time.now - 1.month).strftime("%b #{middle_number}")
        @assignment = @course.assignments.create!(
          title: "Test Assignment",
          points_possible: 10,
          due_at: expected_date
        )
        section = @course.course_sections.create!(name: "new section")
        @assignment.assignment_overrides.create! do |override|
          override.set = section
          override.title = "All"
        end

        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations
        driver.execute_script "$('.edit_assignment').first().hover().click()"
        assignment_title = f("#assign_#{@assignment.id}_assignment_name")
        assignment_points_possible = f("#assign_#{@assignment.id}_assignment_points")
        replace_content(assignment_title, "")
        replace_content(assignment_points_possible, "")
        wait_for_ajaximations
        expect_new_page_load { fj(".more_options:eq(1)").click }
        expect(f("#assignment_name").text).to match ""
        expect(f("#assignment_points_possible").text).to match ""

        first_input_val = driver.execute_script("return $('.DueDateInput__Container:first input').val();")
        expect(first_input_val).to match expected_date
        second_input_val = driver.execute_script("return $('.DueDateInput__Container:last input').val();")
        expect(second_input_val).to match ""
      end
    end

    it "validates that a group category is selected", priority: "1" do
      assignment_name = "first test assignment"
      @assignment = @course.assignments.create({
                                                 name: assignment_name,
                                                 assignment_group: @course.assignment_groups.create!(name: "default")
                                               })

      get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
      f("#has_group_category").click
      f(%(span[data-testid="group-set-close"])).click
      f(".btn-primary[type=submit]").click
      wait_for_ajaximations
      error_box = f(".errorBox[role=alert]")
      expect(f(".error_text", error_box).text).to eq "Please create a group set"
    end

    it "shows assignment details, un-editable, for concluded teachers", priority: "2" do
      @teacher.enrollments.first.conclude
      @assignment = @course.assignments.create({
                                                 name: "assignment after concluded",
                                                 assignment_group: @course.assignment_groups.create!(name: "default")
                                               })

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      expect(f(".description.teacher-version")).to be_present
      expect(f("#content")).not_to contain_css(".edit_assignment_link")
    end

    it "shows course name in the canvas for elementary header" do
      toggle_k5_setting(@course.account)
      get "/courses/#{@course.id}/assignments"
      name = f(".k5-heading-course-name")
      expect(name).to be_displayed
      expect(name.text).to eq @course.name
    end

    it "shows course friendly name in the canvas for elementary header if defined" do
      toggle_k5_setting(@course.account)
      @course.friendly_name = "Well hello there"
      @course.save!
      get "/courses/#{@course.id}/assignments"
      name = f(".k5-heading-course-name")
      expect(name).to be_displayed
      expect(name.text).to eq "Well hello there"
    end

    context "group assignments" do
      before(:once) do
        ag = @course.assignment_groups.first
        @assignment1, @assignment2 = [1, 2].map do |i|
          gc = GroupCategory.create(name: "gc#{i}", context: @course)
          group = @course.groups.create!(group_category: gc)
          group.users << student_in_course(course: @course, active_all: true).user
          ag.assignments.create!(
            context: @course,
            name: "assignment#{i}",
            group_category: gc,
            submission_types: "online_text_entry",
            peer_reviews: "1",
            automatic_peer_reviews: true
          )
        end
        submission = @assignment1.submit_homework(@student)
        submission.submission_type = "online_text_entry"
        submission.save!
      end

      it "does not allow group set to be changed if there are submissions", priority: "1" do
        get "/courses/#{@course.id}/assignments/#{@assignment1.id}/edit"
        # be_disabled
        expect(f("#assignment_group_category_id")).to be_disabled
      end

      it "still shows deleted group set only on an attached assignment with submissions", priority: "2" do
        @assignment1.group_category.destroy
        @assignment2.group_category.destroy

        # ensure neither deleted group shows up on an assignment with no submissions
        get "/courses/#{@course.id}/assignments/#{@assignment2.id}/edit"

        expect(f("#assignment_group_category_id")).not_to include_text @assignment1.group_category.name
        expect(f("#assignment_group_category_id")).not_to include_text @assignment2.group_category.name

        # ensure an assignment attached to a deleted group shows the group it's attached to,
        # but no other deleted groups, and that the dropdown is disabled
        get "/courses/#{@course.id}/assignments/#{@assignment1.id}/edit"

        expect(get_value("#assignment_group_category_id")).to eq @assignment1.group_category.id.to_s
        expect(f("#assignment_group_category_id")).not_to include_text @assignment2.group_category.name
        expect(f("#assignment_group_category_id")).to be_disabled
      end

      it "reverts to a blank selection if original group is deleted with no submissions", priority: "2" do
        @assignment2.group_category.destroy
        get "/courses/#{@course.id}/assignments/#{@assignment2.id}/edit"
        expect(f("#assignment_group_category_id option[selected][value='blank']")).to be_displayed
      end

      it "shows and hide the intra-group peer review toggle depending on group setting" do
        get "/courses/#{@course.id}/assignments/#{@assignment2.id}/edit"

        expect(f("#intra_group_peer_reviews")).to be_displayed
        f("#has_group_category").click
        expect(f("#intra_group_peer_reviews")).not_to be_displayed
      end
    end

    context "student annotation" do
      before do
        @course.account.settings[:usage_rights_required] = true
        @course.account.save!
        attachment = attachment_model(content_type: "application/pdf", context: @course)
        @assignment = @course.assignments.create(name: "Student Annotation", submission_types: "student_annotation,online_text_entry", annotatable_attachment_id: attachment.id)
      end

      # EVAL-3711 Remove this test when instui_nav feature flag is removed
      it "creates a student annotation assignment with annotatable attachment with usage rights" do
        get "/courses/#{@course.id}/assignments"
        wait_for_new_page_load { f(".new_assignment").click }
        f("#assignment_name").send_keys("Annotated Test")

        replace_content(f("#assignment_points_possible"), "10")
        click_option("#assignment_submission_type", "Online")

        ["#assignment_annotated_document", "#assignment_text_entry"].each do |element|
          f(element).click
        end

        wait_for_ajaximations

        expect(f("#assignment_annotated_document_info")).to be_displayed

        # select attachment from file explorer
        fxpath('//*[@id="annotated_document_chooser_container"]/div/div[1]/ul/li[1]/button').click
        fxpath('//*[@id="annotated_document_chooser_container"]/div/div[1]/ul/li[1]/ul/li/button').click

        # set usage rights
        f("#usageRightSelector").click
        fxpath('//*[@id="usageRightSelector"]/option[2]').click
        f("#copyrightHolder").send_keys("Me")

        submit_assignment_form
        wait_for_ajaximations

        expect(f("#assignment_show fieldset")).to include_text("a text entry box or a student annotation")
      end

      it "creates a student annotation assignment with annotatable attachment with usage rights with the instui nav feature flag on" do
        @course.root_account.enable_feature!(:instui_nav)
        get "/courses/#{@course.id}/assignments"
        wait_for_new_page_load { f("[data-testid='new_assignment_button']").click }
        f("#assignment_name").send_keys("Annotated Test")

        replace_content(f("#assignment_points_possible"), "10")
        click_option("#assignment_submission_type", "Online")

        ["#assignment_annotated_document", "#assignment_text_entry"].each do |element|
          f(element).click
        end

        wait_for_ajaximations

        expect(f("#assignment_annotated_document_info")).to be_displayed

        # select attachment from file explorer
        fxpath('//*[@id="annotated_document_chooser_container"]/div/div[1]/ul/li[1]/button').click
        fxpath('//*[@id="annotated_document_chooser_container"]/div/div[1]/ul/li[1]/ul/li/button').click

        # set usage rights
        f("#usageRightSelector").click
        fxpath('//*[@id="usageRightSelector"]/option[2]').click
        f("#copyrightHolder").send_keys("Me")

        submit_assignment_form
        wait_for_ajaximations

        expect(f("#assignment_show fieldset")).to include_text("a text entry box or a student annotation")
      end

      it "displays annotatable document to student and submits assignment for grading" do
        course_with_student_logged_in(active_all: true, course: @course)
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"

        expect(f(".submit_annotated_document_option")).to be_displayed
        f(".submit_annotated_document_option").click

        expect(fxpath('//*[@id="submit_annotated_document_form"]/div/iframe')).to be_displayed

        f("#submit_annotated_document_form .btn-primary").click
        wait_for_ajaximations
        expect(f("#right-side-wrapper")).to include_text("Submitted!")
      end
    end

    context "frozen assignment" do
      before do
        stub_freezer_plugin(Assignment::FREEZABLE_ATTRIBUTES.index_with { "true" })
        default_group = @course.assignment_groups.create!(name: "default")
        @frozen_assign = frozen_assignment(default_group)
      end

      it "does not allow assignment group to be deleted by teacher if assignments are frozen", priority: "2" do
        get "/courses/#{@course.id}/assignments"
        fj("#ag_#{@frozen_assign.assignment_group_id}_manage_link").click
        wait_for_ajaximations
        element = f("div#assignment_group_#{@frozen_assign.assignment_group_id}")
        expect(element).to contain_css("a.delete_group.disabled")
      end

      it "does not allow deleting a frozen assignment from index page", priority: "2" do
        get "/courses/#{@course.id}/assignments"
        fj("div#assignment_#{@frozen_assign.id} button.al-trigger").click
        wait_for_ajaximations
        expect(f("div#assignment_#{@frozen_assign.id}")).to contain_css("a.delete_assignment.disabled")
      end

      it "allows editing the due date even if completely frozen", priority: "2" do
        old_due_at = @frozen_assign.due_at
        run_assignment_edit(@frozen_assign) do
          replace_and_proceed(f(".datePickerDateField[data-date-type='due_at']"), "Sep 20, 2012")
        end

        expect(f(".assignment_dates").text).to match(/Sep 20, 2012/)
        # some sort of time zone issue is occurring with Sep 20, 2012 - it rolls back a day and an hour locally.
        expect(@frozen_assign.reload.due_at.to_i).not_to eq old_due_at.to_i
      end
    end

    # This should be part of a spec that follows a critical path through
    #  the draft state index page, but does not need to be a lone wolf
    it "deletes assignments", priority: "1" do
      skip_if_safari(:alert)
      ag = @course.assignment_groups.first
      as = @course.assignments.create({ assignment_group: ag })

      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations

      f("#assignment_#{as.id} .al-trigger").click
      wait_for_ajaximations
      f("#assignment_#{as.id} .delete_assignment").click

      accept_alert
      wait_for_ajaximations
      expect(f("#content")).not_to contain_css("#assignment_#{as.id}")

      as.reload
      expect(as.workflow_state).to eq "deleted"
    end

    it "reorders assignments with drag and drop", priority: "2" do
      ag = @course.assignment_groups.first
      as = []
      4.times do |i|
        as << @course.assignments.create!(name: "assignment_#{i}", assignment_group: ag)
      end
      expect(as.collect(&:position)).to eq [1, 2, 3, 4]

      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations
      # wait for jQuery UI sortable to be initialized
      expect(f(".collectionViewItems.ui-sortable")).to be_displayed
      drag_with_js("#assignment_#{as[0].id} .draggable-handle", 0, 50)
      wait_for_ajaximations

      as.each(&:reload)
      expect(as.collect(&:position)).to eq [2, 1, 3, 4]
    end

    context "with modules" do
      before do
        @module = @course.context_modules.create!(name: "module 1")
        @assignment = @course.assignments.create!(name: "assignment 1")
        @a2 = @course.assignments.create!(name: "assignment 2")
        @a3 = @course.assignments.create!(name: "assignment 3")
        @module.add_item type: "assignment", id: @assignment.id
        @module.add_item type: "assignment", id: @a2.id
        @module.add_item type: "assignment", id: @a3.id
      end

      it "shows the new modules sequence footer", priority: "2" do
        get "/courses/#{@course.id}/assignments/#{@a2.id}"
        wait_for_ajaximations
        expect(f("#sequence_footer .module-sequence-footer")).to be_present
      end
    end

    context "with an LTI 1.3 Tool with custom params" do
      let(:tool) do
        @course.context_external_tools.create!(
          name: "LTI Test Tool",
          consumer_key: "key",
          shared_secret: "secret",
          use_1_3: true,
          developer_key: DeveloperKey.create!,
          tool_id: "LTI Test Tool",
          url: "http://lti13testtool.docker/launch"
        )
      end
      let(:custom_params) do
        {
          "lti_assignment_id" => "$com.instructure.Assignment.lti.id"
        }
      end
      let(:content_tag) { ContentTag.new(url: tool.url, content: tool) }
      let(:assignment) do
        @course.assignment_groups.first.assignments.create!(title: "custom params",
                                                            lti_resource_link_custom_params: custom_params,
                                                            submission_types: "external_tool",
                                                            context: @course,
                                                            points_possible: 10,
                                                            external_tool_tag: content_tag,
                                                            workflow_state: "unpublished")
      end

      it "doesn't delete the custom params when publishing from the index page" do
        assignment
        get "/courses/#{@course.id}/assignments"
        f("#assignment_#{assignment.id} .publish-icon").click
        wait_for_ajaximations

        expect(assignment.reload.primary_resource_link.custom).to eq(custom_params)
      end

      it "doesn't delete the custom params when editing from the index page" do
        assignment
        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations
        f("#assign_#{assignment.id}_manage_link").click
        wait_for_ajaximations
        f("#assignment_#{assignment.id} .edit_assignment").click
        f("#assign_#{assignment.id}_assignment_points").send_keys("5")

        submit_form(fj(".form-dialog:visible"))

        expect(assignment.reload.primary_resource_link.custom).to eq(custom_params)
      end
    end

    context "publishing" do
      before do
        ag = @course.assignment_groups.first
        @assignment = ag.assignments.create! context: @course, title: "to publish"
        @assignment.unpublish
      end

      it "allows publishing from the index page", priority: "2" do
        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations
        f("#assignment_#{@assignment.id} .publish-icon").click
        wait_for_ajaximations
        expect(@assignment.reload).to be_published
        icon = f("#assignment_#{@assignment.id} .publish-icon")
        expect(icon).to have_attribute("aria-label", "Published")
      end

      it "shows submission scores for students on index page", priority: "2" do
        @assignment.update(points_possible: 15)
        @assignment.publish
        course_with_student_logged_in(active_all: true, course: @course)
        @assignment.grade_student(@student, grade: 14, grader: @teacher)
        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations
        expect(f("#assignment_#{@assignment.id} .js-score .non-screenreader")
            .text).to match "14/15 pts"
      end

      it "allows publishing from the show page", priority: "1" do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"

        f("#assignment_publish_button").click
        wait_for_ajaximations

        expect(@assignment.reload).to be_published
        expect(f("#assignment_publish_button")).to include_text("Published")
      end

      it "has a link to speedgrader from the show page", priority: "1" do
        @assignment.publish
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        speedgrader_link = f(".icon-speed-grader")
        speedgrader_link_text = "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

        expect(speedgrader_link.attribute("href")).to include(speedgrader_link_text)
      end

      it "shows publishing status on the edit page", priority: "2" do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
        wait_for_ajaximations

        expect(f("#edit_assignment_header").text).to match "Not Published"
      end

      context "with overrides" do
        before do
          @course.course_sections.create! name: "HI"
          @assignment.assignment_overrides.create! do |override|
            override.set = @course.course_sections.first
            override.due_at = 1.day.ago
            override.due_at_overridden = true
          end
        end

        it "does not overwrite overrides if published twice from the index page", priority: "2" do
          get "/courses/#{@course.id}/assignments"

          f("#assignment_#{@assignment.id} .publish-icon").click
          keep_trying_until { @assignment.reload.published? }

          # need to make sure buttons
          expect(f("#assignment_#{@assignment.id} .publish-icon")).not_to have_class("disabled")

          f("#assignment_#{@assignment.id} .publish-icon").click
          wait_for_ajaximations
          keep_trying_until { !@assignment.reload.published? }

          expect(@assignment.reload.active_assignment_overrides.count).to eq 1
        end

        it "does not overwrite overrides if published twice from the show page", priority: "2" do
          get "/courses/#{@course.id}/assignments/#{@assignment.id}"
          wait_for_ajaximations

          f("#assignment_publish_button").click
          wait_for_ajaximations
          expect(@assignment.reload).to be_published

          f("#assignment_publish_button").click
          wait_for_ajaximations
          expect(@assignment.reload).not_to be_published

          expect(@assignment.reload.active_assignment_overrides.count).to eq 1
        end
      end
    end

    context "save to sis" do
      it "does not show when no passback configured", priority: "1" do
        get "/courses/#{@course.id}/assignments/new"
        wait_for_ajaximations
        expect(f("#content")).not_to contain_css("#assignment_post_to_sis")
      end

      it "shows when powerschool is enabled", priority: "1" do
        Account.default.set_feature_flag!("post_grades", "on")
        @course.sis_source_id = "xyz"
        @course.save

        get "/courses/#{@course.id}/assignments/new"
        wait_for_ajaximations
        expect(f("#assignment_post_to_sis")).to_not be_nil
      end

      it "shows when post_grades lti tool installed", priority: "1" do
        create_post_grades_tool

        get "/courses/#{@course.id}/assignments/new"
        wait_for_ajaximations
        expect(f("#assignment_post_to_sis")).to_not be_nil
      end

      it "does not show when post_grades lti tool not installed", priority: "1" do
        Account.default.set_feature_flag!("post_grades", "off")

        get "/courses/#{@course.id}/assignments/new"
        wait_for_ajaximations
        expect(f("#content")).not_to contain_css("#assignment_post_to_sis")
      end
    end

    # EVAL-3711 Remove this test when instui_nav feature flag is removed
    it "goes to the assignment index page from left nav", priority: "1" do
      get "/courses/#{@course.id}"
      f("#wrapper .assignments").click
      wait_for_ajaximations
      expect(f(".header-bar-right .new_assignment")).to include_text("Assignment")
    end

    it "goes to the assignment index page from left nav with the instui nav feature flag on", priority: "1" do
      @course.root_account.enable_feature!(:instui_nav)
      get "/courses/#{@course.id}"
      f("#wrapper .assignments").click
      wait_for_ajaximations
      expect(f("[data-testid='new_assignment_button']")).to include_text("Assignment")
    end
  end

  context "when a public course is accessed" do
    include_context "public course as a logged out user"

    it "displays assignments", priority: "1" do
      public_course.assignments.create!(name: "assignment 1")
      get "/courses/#{public_course.id}/assignments"
      validate_selector_displayed(".assignment.search_show")
    end
  end

  context "moderated grading" do
    before do
      course_with_teacher_logged_in
      @course.start_at = nil
      @course.save!
      @assignment = @course.assignments.create({ name: "Test Moderated Assignment" })
      @assignment.update(
        moderated_grading: true,
        grader_count: 1,
        final_grader: @teacher
      )
      @assignment.publish
    end

    it "denies access for a regular student to the moderation page", priority: "1" do
      course_with_student_logged_in({ course: @course })
      get "/courses/#{@course.id}/assignments/#{@assignment.id}/moderate"
      expect(f("#unauthorized_message")).to be_displayed
    end

    it "does not show the moderation page if it is not a moderated assignment", priority: "2" do
      @assignment.update_attribute(:moderated_grading, false)
      get "/courses/#{@course.id}/assignments/#{@assignment.id}/moderate"
      expect(f("#content h1").text).to eql "Whoops... Looks like nothing is here!"
    end
  end

  context "post to sis default setting" do
    before do
      account_model
      @account.set_feature_flag! "post_grades", "on"
      course_with_teacher_logged_in(active_all: true, account: @account)
    end

    it "defaults to post grades if account setting is enabled", priority: "2" do
      @account.settings[:sis_default_grade_export] = { locked: false, value: true }
      @account.save!

      get "/courses/#{@course.id}/assignments/new"
      expect(is_checked("#assignment_post_to_sis")).to be_truthy
    end

    it "does not default to post grades if account setting is not enabled", priority: "2" do
      get "/courses/#{@course.id}/assignments/new"
      expect(is_checked("#assignment_post_to_sis")).to be_falsey
    end
  end

  context "adding new assignment groups from assignment creation page" do
    before do
      course_with_teacher_logged_in
      @new_group = "fine_leather_jacket"
      get "/courses/#{@course.id}/assignments/new"
      click_option("#assignment_group_id", "[ Create Group ]")

      # type something in here so you can check to make sure it was not added
      fj("div.controls > input:visible").send_keys(@new_group)
    end

    it "adds a new assignment group", priority: "1" do
      fj(".button_type_submit:visible").click
      wait_for_ajaximations

      expect(f("#assignment_group_id")).to include_text(@new_group)
    end

    it "cancels adding new assignment group via the cancel button", priority: "2" do
      fj(".cancel-button:visible").click
      wait_for_ajaximations

      expect(f("#assignment_group_id")).not_to include_text(@new_group)
    end

    it "cancels adding new assignment group via the x button", priority: "2" do
      fj(".ui-dialog-titlebar-close:visible").click
      wait_for_ajaximations

      expect(f("#assignment_group_id")).not_to include_text(@new_group)
    end
  end

  context "with restrict_quantitative_data" do
    all_options = ["Percentage", "Complete/Incomplete", "Points", "Letter Grade", "GPA Scale", "Not Graded"]

    before do
      course_with_teacher_logged_in
    end

    context "turned off" do
      it "show all options on create" do
        get "/courses/#{@course.id}/assignments/new"
        wait_for_ajaximations

        expect(get_options("#assignment_grading_type").map(&:text)).to eq all_options
      end

      context "index page" do
        it "shows submission score and letter grade for students on index page", priority: "2" do
          @assignment = @course.assignments.create! context: @course, title: "to publish"
          @assignment.update(points_possible: 10, grading_type: "letter_grade")
          @assignment.publish
          course_with_student_logged_in(active_all: true, course: @course)
          @assignment.grade_student(@student, grade: 10, grader: @teacher)

          get "/courses/#{@course.id}/assignments"
          wait_for_ajaximations

          expect(f("#assignment_#{@assignment.id} .js-score .non-screenreader").text).to match "10/10 pts  |  A"
          expect(f("#assignment_#{@assignment.id} .js-score .screenreader-only").text).to match "Score: 10 out of 10 points. Grade: A"
        end

        it "shows percentage if percent type", priority: "2" do
          @assignment = @course.assignments.create! context: @course, title: "to publish"
          @assignment.update(points_possible: 10, grading_type: "percent")
          @assignment.publish
          course_with_student_logged_in(active_all: true, course: @course)
          @assignment.grade_student(@student, grade: "88%", grader: @teacher)

          get "/courses/#{@course.id}/assignments"
          wait_for_ajaximations

          expect(f("#assignment_#{@assignment.id} .js-score .non-screenreader").text).to match "8.8/10 pts  |  88%"
          expect(f("#assignment_#{@assignment.id} .js-score .screenreader-only").text).to match "Score: 8.8 out of 10 points. Grade: 88%"
        end

        it "shows letter grade if points type", priority: "2" do
          @assignment = @course.assignments.create! context: @course, title: "to publish"
          @assignment.update(points_possible: 10, grading_type: "points")
          @assignment.publish
          course_with_student_logged_in(active_all: true, course: @course)
          @assignment.grade_student(@student, grade: 8, grader: @teacher)

          get "/courses/#{@course.id}/assignments"
          wait_for_ajaximations

          expect(f("#assignment_#{@assignment.id} .js-score .non-screenreader").text).to match "8/10 pts"
          expect(f("#assignment_#{@assignment.id} .js-score .screenreader-only").text).to match "Score: 8 out of 10 points."
        end
      end

      context "creation and edit" do
        it "show all options on edit" do
          @assignment = @course.assignments.create({ name: "Test Assignment" })
          get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
          wait_for_ajaximations

          expect(get_options("#assignment_grading_type").map(&:text)).to eq all_options
        end
      end

      context "assignment show page" do
        it "shows points for teachers" do
          @assignment = @course.assignments.create({ name: "Test Assignment" })
          get "/courses/#{@course.id}/assignments/#{@assignment.id}"
          wait_for_ajaximations
          expect(ff("div .control-label").map(&:text)).to include "Points"
        end

        it "shows points for students" do
          course_with_student_logged_in(active_all: true, course: @course)

          @assignment = @course.assignments.create({ name: "Test Assignment" })
          get "/courses/#{@course.id}/assignments/#{@assignment.id}"
          wait_for_ajaximations
          expect(ff("div .title").map(&:text)).to include "Points"
        end

        context "with rubric" do
          before do
            rubric = @course.rubrics.create!
            rubric.data = [{ description: "Description of criterion",
                             long_description: "",
                             points: 5.0,
                             id: "_7491",
                             criterion_use_range: false,
                             ratings: [{ description: "Full Marks", long_description: "", points: 5.0, criterion_id: "_7491", id: "blank" },
                                       { description: "No Marks", long_description: "", points: 0.0, criterion_id: "_7491", id: "blank_2" }] }]
            rubric.save!

            @course_rubric_association = RubricAssociation.create!(
              rubric:,
              association_object: @course,
              context: @course,
              purpose: "bookmark"
            )

            @assignment = @course.assignments.create({ name: "Test Assignment" })
            @assignment_rubric_association = RubricAssociation.generate(@teacher, rubric, @course, ActiveSupport::HashWithIndifferentAccess.new({
                                                                                                                                                  hide_score_total: "0",
                                                                                                                                                  purpose: "grading",
                                                                                                                                                  skip_updating_points_possible: false,
                                                                                                                                                  update_if_existing: true,
                                                                                                                                                  use_for_grading: "1",
                                                                                                                                                  association_object: @assignment
                                                                                                                                                }))
          end

          it "show points and totals" do
            get "/courses/#{@course.id}/assignments/#{@assignment.id}"
            wait_for_ajaximations

            expect(ff("div .rating-main")[0].text).to match "5 pts\nFull Marks"
            expect(ff("div .rating-main")[1].text).to match "0 pts\nNo Marks"
            expect(ff("div .points_form")[0].text).to match "5 pts"
            expect(ff("div .total_points_holder")[0].text).to match "Total Points:"
          end
        end
      end
    end

    context "turned on" do
      before do
        Account.default.enable_feature! :restrict_quantitative_data
        Account.default.settings[:restrict_quantitative_data] = { value: true, locked: true }
        Account.default.save!
        @course.restrict_quantitative_data = true
        @course.save!
      end

      context "index" do
        it "shows only submission letter grade for students on index page", priority: "2" do
          @assignment = @course.assignments.create! context: @course, title: "to publish"
          @assignment.update(points_possible: 10, grading_type: "letter_grade")
          @assignment.publish
          course_with_student_logged_in(active_all: true, course: @course)
          @assignment.grade_student(@student, grade: 10, grader: @teacher)

          get "/courses/#{@course.id}/assignments"
          wait_for_ajaximations

          expect(f("#assignment_#{@assignment.id} .js-score .non-screenreader").text).to match "A"
          expect(f("#assignment_#{@assignment.id} .js-score .screenreader-only").text).to match "Grade: A"
        end

        it "shows Complete for students with 0/0 score on index page", priority: "2" do
          @assignment = @course.assignments.create! context: @course, title: "to publish"
          @assignment.update(points_possible: 0, grading_type: "letter_grade")
          @assignment.publish
          course_with_student_logged_in(active_all: true, course: @course)
          @assignment.grade_student(@student, grade: 0, grader: @teacher)

          get "/courses/#{@course.id}/assignments"
          wait_for_ajaximations

          expect(f("#assignment_#{@assignment.id} .js-score .non-screenreader").text).to match "Complete"
          expect(f("#assignment_#{@assignment.id} .js-score .screenreader-only").text).to match "Grade: Complete"
        end

        it "shows A for students with 1/0 score on index page", priority: "2" do
          @assignment = @course.assignments.create! context: @course, title: "to publish"
          @assignment.update(points_possible: 0, grading_type: "letter_grade")
          @assignment.publish
          course_with_student_logged_in(active_all: true, course: @course)
          @assignment.grade_student(@student, grade: 1, grader: @teacher)

          get "/courses/#{@course.id}/assignments"
          wait_for_ajaximations

          expect(f("#assignment_#{@assignment.id} .js-score .non-screenreader").text).to match "A"
          expect(f("#assignment_#{@assignment.id} .js-score .screenreader-only").text).to match "Grade: A"
        end

        it "shows -1 for students with -1/0 score on index page", priority: "2" do
          @assignment = @course.assignments.create! context: @course, title: "to publish"
          @assignment.update(points_possible: 0, grading_type: "letter_grade")
          @assignment.publish
          course_with_student_logged_in(active_all: true, course: @course)
          @assignment.grade_student(@student, grade: -1, grader: @teacher)

          get "/courses/#{@course.id}/assignments"
          wait_for_ajaximations

          expect(f("#assignment_#{@assignment.id} .js-score .non-screenreader").text).to match "-1"
          expect(f("#assignment_#{@assignment.id} .js-score .screenreader-only").text).to match "Grade: -1"
        end

        it "shows points possible for teachers on index page", priority: "2" do
          @assignment = @course.assignments.create! context: @course, title: "to publish"
          @assignment.update(points_possible: 10, grading_type: "letter_grade")
          @assignment.publish
          course_with_teacher_logged_in(active_all: true, course: @course)

          get "/courses/#{@course.id}/assignments"
          wait_for_ajaximations

          expect(f("#assignment_#{@assignment.id} .js-score .non-screenreader").text).to match "10 pts"
        end

        it "shows letter grade if percent type", priority: "2" do
          @assignment = @course.assignments.create! context: @course, title: "to publish"
          @assignment.update(points_possible: 10, grading_type: "percent")
          @assignment.publish
          course_with_student_logged_in(active_all: true, course: @course)
          @assignment.grade_student(@student, grade: "88%", grader: @teacher)

          get "/courses/#{@course.id}/assignments"
          wait_for_ajaximations

          expect(f("#assignment_#{@assignment.id} .js-score .non-screenreader").text).to match "B+"
          expect(f("#assignment_#{@assignment.id} .js-score .screenreader-only").text).to match "Grade: B+"
        end

        it "shows letter grade if points type", priority: "2" do
          @assignment = @course.assignments.create! context: @course, title: "to publish"
          @assignment.update(points_possible: 10, grading_type: "points")
          @assignment.publish
          course_with_student_logged_in(active_all: true, course: @course)
          @assignment.grade_student(@student, grade: 8, grader: @teacher)

          get "/courses/#{@course.id}/assignments"
          wait_for_ajaximations

          expect(f("#assignment_#{@assignment.id} .js-score .non-screenreader").text).to match "B-"
          expect(f("#assignment_#{@assignment.id} .js-score .screenreader-only").text).to match "Grade: B-"
        end

        it "shows A if points type, pointsPossible is 0 and score is more than 0", priority: "2" do
          @assignment = @course.assignments.create! context: @course, title: "to publish"
          @assignment.update(points_possible: 0, grading_type: "points")
          @assignment.publish
          course_with_student_logged_in(active_all: true, course: @course)
          @assignment.grade_student(@student, grade: 3, grader: @teacher)

          get "/courses/#{@course.id}/assignments"
          wait_for_ajaximations

          expect(f("#assignment_#{@assignment.id} .js-score .non-screenreader").text).to match "A"
          expect(f("#assignment_#{@assignment.id} .js-score .screenreader-only").text).to match "Grade: A"
        end

        it "shows nothing if points type, pointsPossible is 0 and score is 0 or less", priority: "2" do
          @assignment = @course.assignments.create! context: @course, title: "to publish"
          @assignment.update(points_possible: 0, grading_type: "points")
          @assignment.publish
          course_with_student_logged_in(active_all: true, course: @course)
          @assignment.grade_student(@student, grade: 0, grader: @teacher)

          get "/courses/#{@course.id}/assignments"
          wait_for_ajaximations

          expect(f("#assignment_#{@assignment.id} .js-score .non-screenreader").text).to match ""
          expect(f("#assignment_#{@assignment.id} .js-score .screenreader-only").text).to match ""
        end

        it "shows complete if pass_fail type, pointsPossible is 0 and score is complete", priority: "2" do
          @assignment = @course.assignments.create! context: @course, title: "to publish"
          @assignment.update(points_possible: 0, grading_type: "pass_fail")
          @assignment.publish
          course_with_student_logged_in(active_all: true, course: @course)
          @assignment.grade_student(@student, grade: "complete", grader: @teacher)

          get "/courses/#{@course.id}/assignments"
          wait_for_ajaximations

          expect(f("#assignment_#{@assignment.id} .js-score .non-screenreader").text).to match "Complete"
          expect(f("#assignment_#{@assignment.id} .js-score .screenreader-only").text).to match "Grade: Complete"
        end

        it "shows A if letter grade type, pointsPossible is 0 and score is more than 0", priority: "2" do
          @assignment = @course.assignments.create! context: @course, title: "to publish"
          @assignment.update(points_possible: 0, grading_type: "letter_grade")
          @assignment.publish
          course_with_student_logged_in(active_all: true, course: @course)
          @assignment.grade_student(@student, grade: 3, grader: @teacher)

          get "/courses/#{@course.id}/assignments"
          wait_for_ajaximations

          expect(f("#assignment_#{@assignment.id} .js-score .non-screenreader").text).to match "A"
          expect(f("#assignment_#{@assignment.id} .js-score .screenreader-only").text).to match "Grade: A"
        end

        it "shows the course scheme letter grade if letter grade type, pointsPossible is > 0 and score is less than pointsPossible" do
          @course_standard = @course.grading_standards.create!(title: "course standard", standard_data: { f: { name: "F", value: "" } })
          @assignment = @course.assignments.create! context: @course, title: "to publish", grading_standard_id: @course_standard.id
          @assignment.update(points_possible: 100, grading_type: "letter_grade")
          @assignment.publish
          course_with_student_logged_in(active_all: true, course: @course)
          @assignment.grade_student(@student, grade: 90, grader: @teacher)

          get "/courses/#{@course.id}/assignments"
          wait_for_ajaximations

          expect(f("#assignment_#{@assignment.id} .js-score .non-screenreader").text).to match "F"
          expect(f("#assignment_#{@assignment.id} .js-score .screenreader-only").text).to match "Grade: F"
        end
      end

      context "creation and edit" do
        it "show all options on create" do
          get "/courses/#{@course.id}/assignments/new"
          wait_for_ajaximations

          expect(get_options("#assignment_grading_type").map(&:text)).to eq all_options
        end

        it "show only qualitative options on edit" do
          @assignment = @course.assignments.create({ name: "Test Assignment" })
          get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
          wait_for_ajaximations

          expect(get_options("#assignment_grading_type").map(&:text)).to eq all_options
        end
      end

      context "assignment show page" do
        it "shows points for teachers" do
          @assignment = @course.assignments.create({ name: "Test Assignment" })
          get "/courses/#{@course.id}/assignments/#{@assignment.id}"
          wait_for_ajaximations
          expect(ff("div .control-label").map(&:text)).to include "Points"
        end

        it "does not show points for students" do
          course_with_student_logged_in(active_all: true, course: @course)

          @assignment = @course.assignments.create({ name: "Test Assignment" })
          get "/courses/#{@course.id}/assignments/#{@assignment.id}"
          wait_for_ajaximations
          expect(ff("div .title").map(&:text)).not_to include "Points"
        end

        context "with rubric" do
          before do
            rubric = @course.rubrics.create!
            rubric.data = [{ description: "Description of criterion",
                             long_description: "",
                             points: 5.0,
                             id: "_7491",
                             criterion_use_range: false,
                             ratings: [{ description: "Full Marks", long_description: "", points: 5.0, criterion_id: "_7491", id: "blank" },
                                       { description: "No Marks", long_description: "", points: 0.0, criterion_id: "_7491", id: "blank_2" }] }]
            rubric.save!

            @course_rubric_association = RubricAssociation.create!(
              rubric:,
              association_object: @course,
              context: @course,
              purpose: "bookmark"
            )

            @assignment = @course.assignments.create({ name: "Test Assignment" })
            @assignment_rubric_association = RubricAssociation.generate(@teacher, rubric, @course, ActiveSupport::HashWithIndifferentAccess.new({
                                                                                                                                                  hide_score_total: "0",
                                                                                                                                                  purpose: "grading",
                                                                                                                                                  skip_updating_points_possible: false,
                                                                                                                                                  update_if_existing: true,
                                                                                                                                                  use_for_grading: "1",
                                                                                                                                                  association_object: @assignment
                                                                                                                                                }))
          end

          it "hide points and totals" do
            get "/courses/#{@course.id}/assignments/#{@assignment.id}"
            wait_for_ajaximations

            expect(ff("div .rating-main")[0].text).to match "Full Marks"
            expect(ff("div .rating-main")[1].text).to match "No Marks"
            expect(ff("div .points_form")[0].text).to match ""
            expect(ff("div .total_points_holder")[0].text).to match ""
          end
        end
      end
    end
  end
end
