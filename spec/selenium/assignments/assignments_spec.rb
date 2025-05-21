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
require_relative "../helpers/context_modules_common"
require_relative "../helpers/items_assign_to_tray"
require_relative "page_objects/assignment_create_edit_page"

describe "assignments" do
  include_context "in-process server selenium tests"
  include FilesCommon
  include AssignmentsCommon
  include AdminSettingsCommon
  include ContextModulesCommon
  include CustomScreenActions
  include CustomSeleniumActions
  include K5Common
  include ItemsAssignToTray

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

    it "shows SpeedGrader link when published" do
      @assignment = @course.assignments.create({ name: "Test Moderated Assignment" })
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      expect(f("#speed-grader-link-container")).to be_present
    end

    it "hides SpeedGrader link when unpublished" do
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

    context "re-upload submissions" do
      def create_text_file(file_path, content)
        File.write(file_path, content)
      end

      def create_zip_file(zip_path, files)
        Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
          files.each do |file|
            zipfile.add(File.basename(file), file)
          end
        end
      end

      before do
        # Create assignment with at least one submission
        student_in_course(course: @course, active_all: true)
        @assignment = @course.assignments.create!(
          name: "Assignment 1",
          submission_types: "online_text_entry"
        )
        submission = @assignment.submit_homework(@student)
        submission.submission_type = "online_text_entry"
        submission.save!

        # Go to assignment show page
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        # Download submissions
        f(".download_submissions_link").click
        wait_for_ajaximations
        fj(".ui-dialog-titlebar-close:visible").click
        wait_for_ajaximations
        # Click Re-Upload Submissions link
        f(".upload_submissions_link").click
        wait_for_ajaximations
      end

      it "displays correct buttons" do
        expect(f("#choose_file_button")).to be_displayed
        Dir.mktmpdir do |tmpdir|
          # Create text files in the temp directory
          txt_file_1 = File.join(tmpdir, "file1.txt")
          txt_file_2 = File.join(tmpdir, "file2.txt")

          create_text_file(txt_file_1, "This is the content of file1.")
          create_text_file(txt_file_2, "This is the content of file2.")

          # Create the zip file in the temp directory
          zip_file_path = File.join(tmpdir, "my_files.zip")
          create_zip_file(zip_file_path, [txt_file_1, txt_file_2])

          f('input[name="submissions_zip"]').send_keys(zip_file_path)
          expect(f("#reuploaded_submissions_button")).to be_displayed
        end
      end

      it "displays error text if incorrect file type" do
        Dir.mktmpdir do |tmpdir|
          # Create text files in the temp directory
          txt_file_1 = File.join(tmpdir, "file1.txt")
          create_text_file(txt_file_1, "This is the content of file1.")

          f('input[name="submissions_zip"]').send_keys(txt_file_1)
          expect(f("[data-testid='error-message-container']")).to be_displayed
        end
      end
    end

    context "submission methods" do
      it "preserves submission methods when saving from index page", priority: "1" do
        # Create assignment with multiple submission methods
        assignment = @course.assignments.create!(
          name: "Test Assignment",
          submission_types: "online_text_entry,online_url,online_upload",
          assignment_group: @course.assignment_groups.first
        )

        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations

        edit_assignment(assignment.id, submit: true)
        assignment.reload
        expect(assignment.submission_types).to eq "online_text_entry,online_url,online_upload"
      end

      it "preserves all assignment attributes when opening and submitting without changes using more options", :ignore_js_errors do
        original_assignment = @course.assignments.create!(
          title: "Unchanged Assignment",
          description: "Original description",
          due_at: Time.zone.parse("2025-01-31 17:09:36 UTC"),
          unlock_at: Time.zone.parse("2025-01-25 17:09:36 UTC"),
          lock_at: Time.zone.parse("2025-02-07 17:09:36 UTC"),
          points_possible: 20.0,
          grading_type: "points",
          submission_types: "online_text_entry,online_url,online_upload",
          workflow_state: "published",
          peer_reviews: false,
          automatic_peer_reviews: false,
          anonymous_peer_reviews: false,
          moderated_grading: false,
          grader_count: 0,
          grader_comments_visible_to_graders: true,
          grader_names_visible_to_final_grader: true,
          allowed_attempts: nil,
          muted: true
        )

        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations

        edit_assignment(original_assignment.id, more_options: true)
        f(".btn-primary[type='submit']").click
        wait_for_ajaximations

        assignment = original_assignment.reload
        expect(assignment.title).to eq "Unchanged Assignment"
        expect(assignment.type).to eq "Assignment"
        expect(assignment.due_at).to eq Time.zone.parse("2025-01-31 17:09:36 UTC")
        expect(assignment.unlock_at).to eq Time.zone.parse("2025-01-25 17:09:36 UTC")
        expect(assignment.lock_at).to eq Time.zone.parse("2025-02-07 17:09:36 UTC")
        expect(assignment.points_possible).to eq 20.0
        expect(assignment.grading_type).to eq "points"
        expect(assignment.submission_types).to eq "online_text_entry,online_url,online_upload"
        expect(assignment.workflow_state).to eq "published"
        expect(assignment.peer_reviews).to be false
        expect(assignment.automatic_peer_reviews).to be false
        expect(assignment.anonymous_peer_reviews).to be false
        expect(assignment.moderated_grading).to be false
        expect(assignment.grader_count).to eq 0
        expect(assignment.grader_comments_visible_to_graders).to be true
        expect(assignment.grader_names_visible_to_final_grader).to be true
        expect(assignment.allowed_attempts).to be_nil
        expect(assignment.muted).to be true
      end

      it "preserves all assignment attributes for checkpointed discussion when opening and submitting without changes using more options", :ignore_js_errors do
        sub_account = Account.create!(name: "sub1", parent_account: Account.default)
        @course.update!(account: sub_account)
        sub_account.enable_feature!(:discussion_checkpoints)
        @checkpointed_discussion = DiscussionTopic.create_graded_topic!(course: @course, title: "checkpointed discussion")
        Checkpoints::DiscussionCheckpointCreatorService.call(
          discussion_topic: @checkpointed_discussion,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "everyone", due_at: 2.days.from_now }],
          points_possible: 6
        )
        Checkpoints::DiscussionCheckpointCreatorService.call(
          discussion_topic: @checkpointed_discussion,
          checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
          dates: [{ type: "everyone", due_at: 3.days.from_now }],
          points_possible: 7,
          replies_required: 2
        )

        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations

        edit_assignment(@checkpointed_discussion.assignment.id, more_options: true)
        f(".btn-primary[type='submit']").click
        wait_for_ajaximations

        assignment = @checkpointed_discussion.assignment.reload
        expect(assignment.title).to eq "checkpointed discussion"
        expect(assignment.submission_types).to eq "discussion_topic"
        expect(assignment.workflow_state).to eq "published"
        expect(assignment.type).to eq "Assignment"
        expect(assignment.sub_assignments.first.type).to eq "SubAssignment"
      end

      it "preserves online_upload submission type when editing an assignment" do
        @assignment = @course.assignments.create!(
          title: "Test Assignment",
          points_possible: 10,
          submission_types: "online_upload"
        )

        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations
        edit_assignment(@assignment.id, submit: true)

        expect(@assignment.reload.submission_types).to eq "online_upload"
      end

      it "preserves online_url submission type when editing an assignment" do
        @assignment = @course.assignments.create!(
          title: "Test Assignment",
          points_possible: 10,
          submission_types: "online_url"
        )

        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations
        edit_assignment(@assignment.id, submit: true)

        expect(@assignment.reload.submission_types).to eq "online_url"
      end

      it "preserves none submission type when editing an assignment" do
        @assignment = @course.assignments.create!(
          title: "Test Assignment",
          points_possible: 10,
          submission_types: "none"
        )

        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations
        edit_assignment(@assignment.id, submit: true)

        expect(@assignment.reload.submission_types).to eq "none"
      end

      it "preserves all assignment attributes when opening and submitting without changes" do
        original_assignment = @course.assignments.create!(
          title: "Unchanged Assignment",
          description: "Original description",
          due_at: Time.zone.parse("2025-01-31 17:09:36 UTC"),
          unlock_at: Time.zone.parse("2025-01-25 17:09:36 UTC"),
          lock_at: Time.zone.parse("2025-02-07 17:09:36 UTC"),
          points_possible: 20.0,
          grading_type: "points",
          submission_types: "online_text_entry",
          workflow_state: "published",
          peer_reviews: false,
          automatic_peer_reviews: false,
          anonymous_peer_reviews: false,
          moderated_grading: false,
          grader_count: 0,
          grader_comments_visible_to_graders: true,
          grader_names_visible_to_final_grader: true,
          allowed_attempts: nil,
          muted: true
        )

        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations
        edit_assignment(original_assignment.id, submit: true)

        assignment = original_assignment.reload
        expect(assignment.title).to eq "Unchanged Assignment"
        expect(assignment.type).to eq "Assignment"
        expect(assignment.description).to eq "Original description"
        expect(assignment.due_at).to eq Time.zone.parse("2025-01-31 17:09:36 UTC")
        expect(assignment.unlock_at).to eq Time.zone.parse("2025-01-25 17:09:36 UTC")
        expect(assignment.lock_at).to eq Time.zone.parse("2025-02-07 17:09:36 UTC")
        expect(assignment.points_possible).to eq 20.0
        expect(assignment.grading_type).to eq "points"
        expect(assignment.submission_types).to eq "online_text_entry"
        expect(assignment.workflow_state).to eq "published"
        expect(assignment.peer_reviews).to be false
        expect(assignment.automatic_peer_reviews).to be false
        expect(assignment.anonymous_peer_reviews).to be false
        expect(assignment.moderated_grading).to be false
        expect(assignment.grader_count).to eq 0
        expect(assignment.grader_comments_visible_to_graders).to be true
        expect(assignment.grader_names_visible_to_final_grader).to be true
        expect(assignment.allowed_attempts).to be_nil
        expect(assignment.muted).to be true
      end

      it "preserves all assignment attributes for checkpointed discussion when opening and submitting without changes" do
        sub_account = Account.create!(name: "sub1", parent_account: Account.default)
        sub_account.enable_feature!(:discussion_checkpoints)
        @course.update!(account: sub_account)
        @checkpointed_discussion = DiscussionTopic.create_graded_topic!(course: @course, title: "checkpointed discussion")
        Checkpoints::DiscussionCheckpointCreatorService.call(
          discussion_topic: @checkpointed_discussion,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "everyone", due_at: 2.days.from_now }],
          points_possible: 6
        )
        Checkpoints::DiscussionCheckpointCreatorService.call(
          discussion_topic: @checkpointed_discussion,
          checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
          dates: [{ type: "everyone", due_at: 3.days.from_now }],
          points_possible: 7,
          replies_required: 2
        )

        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations
        edit_assignment(@checkpointed_discussion.assignment.id, submit: true)

        assignment = @checkpointed_discussion.assignment.reload
        expect(assignment.title).to eq "checkpointed discussion"
        expect(assignment.submission_types).to eq "discussion_topic"
        expect(assignment.workflow_state).to eq "published"
        expect(assignment.type).to eq "Assignment"
        expect(assignment.sub_assignments.first.type).to eq "SubAssignment"
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

    context "submission attempts" do
      before do
        user_session(@teacher)
      end

      it "validates number of attempts must be less than or equal to 100" do
        get "/courses/#{@course.id}/assignments/new"

        f("#assignment_name").send_keys("Test Assignment")
        click_option("#assignment_submission_type", "Online")
        f("#assignment_text_entry").click
        click_option(find_by_test_id("allowed_attempts_type"), "Limited")

        allowed_attempts_input = find_by_test_id("allowed_attempts_input")
        # 1 attempt is prepopulated so we need to clear it first with backspace
        allowed_attempts_input.send_keys("\b")
        allowed_attempts_input.send_keys("101")

        submit_assignment_form

        error_msg = f("#allowed_attempts_errors")
        expect(error_msg).to include_text("Number of attempts must be less than or equal to 100")
      end

      it "validates number of attempts must be greater than 0" do
        get "/courses/#{@course.id}/assignments/new"

        f("#assignment_name").send_keys("Test Assignment")
        click_option("#assignment_submission_type", "Online")
        f("#assignment_text_entry").click
        click_option(find_by_test_id("allowed_attempts_type"), "Limited")

        allowed_attempts_input = find_by_test_id("allowed_attempts_input")
        allowed_attempts_input.send_keys("\b")
        allowed_attempts_input.send_keys("0")

        submit_assignment_form

        error_msg = f("#allowed_attempts_errors")
        expect(error_msg).to include_text("Number of attempts must be a number greater than 0")
      end

      it "allows valid number of attempts" do
        get "/courses/#{@course.id}/assignments/new"

        f("#assignment_name").send_keys("Test Assignment")
        click_option("#assignment_submission_type", "Online")
        f("#assignment_text_entry").click
        click_option(find_by_test_id("allowed_attempts_type"), "Limited")

        allowed_attempts_input = find_by_test_id("allowed_attempts_input")
        allowed_attempts_input.send_keys("\b")
        allowed_attempts_input.send_keys("5")

        expect_new_page_load { submit_assignment_form }

        # Verify no error message
        expect(f("body")).not_to contain_css("#allowed_attempts_errors")
        assignment = @course.assignments.last
        expect(assignment.allowed_attempts).to eq 5
      end

      it "allows unlimited attempts" do
        get "/courses/#{@course.id}/assignments/new"

        f("#assignment_name").send_keys("Test Assignment")
        click_option("#assignment_submission_type", "Online")
        f("#assignment_text_entry").click
        click_option(find_by_test_id("allowed_attempts_type"), "Unlimited")

        expect_new_page_load { submit_assignment_form }

        # Verify no error message
        expect(f("body")).not_to contain_css("#allowed_attempts_errors")
        assignment = @course.assignments.last
        expect(assignment.allowed_attempts).to be_nil
      end
    end

    # EVAL-3711 Remove this test when instui_nav feature flag is removed
    it "creates an assignment using main add button", :xbrowser, priority: "1" do
      assignment_name = "first assignment"
      # freeze for a certain time, so we don't get unexpected ui complications
      time = Time.zone.parse("#{Time.zone.now.year}-01-07 02:13")
      Timecop.freeze(time) do
        format_time_for_view(time)

        get "/courses/#{@course.id}/assignments"
        # create assignment
        wait_for_new_page_load { f(".new_assignment").click }
        f("#assignment_name").send_keys(assignment_name)
        replace_content(f("#assignment_points_possible"), "10")
        click_option("#assignment_submission_type", "Online")
        ["#assignment_text_entry", "#assignment_online_url", "#assignment_online_upload"].each do |element|
          f(element).click
        end

        submit_assignment_form
        wait_for_ajaximations
        # confirm all our settings were saved and are now displayed
        expect(f("h1.title")).to include_text(assignment_name)
        expect(f("#assignment_show .points_possible")).to include_text("10")

        expect(f("#assignment_show fieldset")).to include_text("a text entry box, a website url, or a file upload")
      end
    end

    it "creates an assignment using main add button with the instui nav feature flag on", :xbrowser, priority: "1" do
      @course.root_account.enable_feature!(:instui_nav)
      assignment_name = "first assignment"
      # freeze for a certain time, so we don't get unexpected ui complications
      time = Time.zone.parse("#{Time.zone.now.year}-01-07 02:13")
      Timecop.freeze(time) do
        format_time_for_view(time)

        get "/courses/#{@course.id}/assignments"
        # create assignment
        wait_for_new_page_load { f("[data-testid='new_assignment_button']").click }
        f("#assignment_name").send_keys(assignment_name)
        replace_content(f("#assignment_points_possible"), "10")
        click_option("#assignment_submission_type", "Online")
        ["#assignment_text_entry", "#assignment_online_url", "#assignment_online_upload"].each do |element|
          f(element).click
        end

        submit_assignment_form
        wait_for_ajaximations
        # confirm all our settings were saved and are now displayed
        expect(f("h1.title")).to include_text(assignment_name)
        expect(f("#assignment_show .points_possible")).to include_text("10")
        expect(f("#assignment_show fieldset")).to include_text("a text entry box, a website url, or a file upload")
      end
    end

    it "only allows an assignment editor to edit points and title if assignment has multiple due dates" do
      middle_number = "15"
      expected_date = 1.month.ago.strftime("%b #{middle_number}")
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
      expect(f("[data-testid='multiple-due-dates-message']")).to be_disabled

      f("[data-testid='close-button']").click
      edit_assignment(@assignment.id, name: "VDD Test Assignment Updated", points: 100, submit: true)

      expect(@assignment.reload.points_possible).to eq 100
      expect(@assignment.title).to eq "VDD Test Assignment Updated"
      # Assert the time didn't change
      expect(@assignment.due_at.strftime("%b %d")).to eq expected_date
    end

    it "preserves assignment submission type when editing an assignment" do
      @assignment = @course.assignments.create!(
        title: "Test Assignment",
        points_possible: 10,
        submission_types: "online_text_entry"
      )

      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations
      edit_assignment(@assignment.id, submit: true)

      expect(@assignment.reload.submission_types).to eq "online_text_entry"
    end

    it "creates a simple assignment and defaults post_to_sis" do
      a = @course.account
      a.settings[:sis_default_grade_export] = { locked: false, value: true }
      a.save!
      assignment_name = "test_assignment_thing_#{rand(10_000)}"
      get "/courses/#{@course.id}/assignments"
      group = @course.assignment_groups.first
      build_assignment_with_type("Assignment", assignment_group_id: group.id, name: assignment_name, points: "10", submit: true)
      wait_for_ajaximations
      assignment = @course.assignments.where(title: assignment_name).last
      expect(f("#assignment_#{@course.assignments.last.id}_settings_delete_item").attribute(:class)).not_to include("disabled")
      expect(assignment).not_to be_nil
      expect(assignment).to be_post_to_sis
    end

    it "creates an assignment with more options", priority: "2" do
      enable_cache do
        expected_text = "Assignment 1"
        # freeze time to avoid ui complications
        time = Time.zone.local(2015, 1, 7, 2, 13)
        Timecop.freeze(time) do
          due_at = format_time_for_datepicker(time)
          points = "25"

          get "/courses/#{@course.id}/assignments"
          group = @course.assignment_groups.first
          AssignmentGroup.where(id: group).update_all(updated_at: 1.hour.ago)
          first_stamp = group.reload.updated_at.to_i
          build_assignment_with_type("Assignment", assignment_group_id: group.id, name: expected_text, points:, due_at:, due_time: "2:13 AM")

          expect_new_page_load { f("[data-testid='more-options-button']").click }

          expect(f("#assignment_name").attribute(:value)).to include(expected_text)
          expect(f("#assignment_points_possible").attribute(:value)).to include(points)

          expect(element_value_for_attr(assign_to_due_date, "value") + ", " + element_value_for_attr(assign_to_due_time, "value")).to eq due_at

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

    it "deselects peer reviews option when peer review box gets hidden" do
      get "/courses/#{@course.id}/assignments/new"

      f("#assignment_name").send_keys("Test Assignment")

      # selects peer reviews option
      f("#assignment_peer_reviews").click
      expect(f("#assignment_peer_reviews")).to be_checked

      # select external tool submission type which will hide the peer review box
      click_option("#assignment_submission_type", "External Tool")
      # select another submission type to display the peer review box
      click_option("#assignment_submission_type", "Online")
      f("#assignment_text_entry").click

      # peer reviews option should be deselected
      expect(f("#assignment_peer_reviews")).not_to be_checked
    end

    context "when user and course are in different timezones" do
      before do
        @teacher.time_zone = "America/New_York"
        @teacher.save!
        @course.time_zone = "America/Los_Angeles"
        @course.save!
      end

      it "does not shift peer reviews assign at date when editing an assignment" do
        peer_reviews_assign_at = (Time.now.utc + 3.days).change(sec: 0)

        get "/courses/#{@course.id}/assignments/new"
        wait_for_ajaximations

        f("#assignment_name").send_keys "assignment with peer reviews"
        click_option("#assignment_submission_type", "Online")
        f("#assignment_text_entry").click
        f("#assignment_peer_reviews").click
        f("#assignment_automatic_peer_reviews").click
        f("#assignment_peer_reviews_assign_at").send_keys peer_reviews_assign_at.strftime("%Y-%m-%d %H:%M") # rubocop:disable Specs/NoStrftime
        f(".save_and_publish").click
        wait_for_ajaximations

        assignment = @course.assignments.order(:id).last
        get "/courses/#{@course.id}/assignments/#{assignment.id}/edit"
        wait_for_ajaximations

        expect(f("#assignment_peer_reviews_assign_at").attribute("value")).to eq format_time_for_view(peer_reviews_assign_at, "%b %-2d, %Y")
      end
    end

    it "keeps erased field on more options click", priority: "2" do
      enable_cache do
        middle_number = "15"
        expected_date = 1.month.ago.strftime("%b #{middle_number}")
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
        edit_assignment(@assignment.id, name: "", points: 0)

        expect_new_page_load { f("[data-testid='more-options-button']").click }
        expect(f("#assignment_name").text).to match ""
        expect(f("#assignment_points_possible").text).to match ""

        expect(element_value_for_attr(assign_to_due_date(0), "value")).to match expected_date
        expect(element_value_for_attr(assign_to_due_date(1), "value")).to eq("")
      end
    end

    it "validates the assignment name" do
      get "/courses/#{@course.id}/assignments/new"
      wait_for_ajaximations

      submit_assignment_form
      # validate assignment name is not empty
      expect(f("#name_errors")).to include_text("Name is required")

      f("#assignment_name").send_keys("a" * 256)
      submit_assignment_form
      # validate assignment name is not too long
      expect(f("#name_errors")).to include_text("Must be fewer than 256 characters")
    end

    it "validates at least one submission type is checked if online submission" do
      get "/courses/#{@course.id}/assignments/new"
      wait_for_ajaximations
      submit_assignment_form
      expect(f("#online_submission_types\\[online_text_entry\\]_errors")).to include_text("Please choose at least one submission type")
    end

    it "validates the points possible" do
      get "/courses/#{@course.id}/assignments/new"
      wait_for_ajaximations
      f("#assignment_name").send_keys("test points possible")

      # clear the default value (0)
      negative_input = "-1"
      f("#assignment_points_possible").send_keys(:backspace)
      f("#assignment_points_possible").send_keys(negative_input)
      submit_assignment_form
      # validate points possible is not negative
      expect(f("#points_possible_errors")).to include_text("Points value must be 0 or greater")

      # clear the last value
      negative_input.each_char { f("#assignment_points_possible").send_keys(:backspace) }
      f("#assignment_points_possible").send_keys("a")
      submit_assignment_form
      # validate points possible is a number
      expect(f("#points_possible_errors")).to include_text("Points value must be a number")

      # clear the last value
      f("#assignment_points_possible").send_keys(:backspace)
      f("#assignment_points_possible").send_keys(1_000_000_000)
      submit_assignment_form
      # validate points possible max
      expect(f("#points_possible_errors")).to include_text("Points value must be 999999999 or less")
    end

    it "validates allowed extensions" do
      assignment = @course.assignments.create!(
        name: "Test allowed extensions",
        submission_types: "online_upload",
        assignment_group: @course.assignment_groups.first
      )

      get "/courses/#{@course.id}/assignments/#{assignment.id}/edit"
      wait_for_ajaximations

      f("#assignment_restrict_file_extensions").click
      submit_assignment_form
      # validate there is at least one file type
      expect(f("#allowed_extensions_errors")).to include_text("Please specify at least one allowed file type")

      f("#assignment_allowed_extensions").send_keys("a" * 256)
      submit_assignment_form
      # validate allowed extensions max
      expect(f("#allowed_extensions_errors")).to include_text("Must be fewer than 256 characters")
    end

    context "invalid allowed extensions" do
      it "ignores invalid extensions if File Uploads is unchecked" do
        assignment = @course.assignments.create!(
          name: "Test invalid allowed extensions with file uploads unchecked",
          submission_types: "online_text_entry,online_upload",
          assignment_group: @course.assignment_groups.first
        )

        get "/courses/#{@course.id}/assignments/#{assignment.id}/edit"
        wait_for_ajaximations

        f("#assignment_restrict_file_extensions").click
        # invalid file extension
        f("#assignment_allowed_extensions").send_keys("a" * 256)
        # unchecking File Uploads clears the error and allow the form to be submitted
        f("#assignment_online_upload").click

        submit_assignment_form

        expect(assignment.reload.submission_types).to eq "online_text_entry"
      end

      it "ignores invalid extensions if Restrict Upload File Types is unchecked" do
        assignment = @course.assignments.create!(
          name: "Test invalid allowed extensions with restrict upload file types unchecked",
          submission_types: "online_text_entry,online_upload",
          assignment_group: @course.assignment_groups.first
        )

        get "/courses/#{@course.id}/assignments/#{assignment.id}/edit"
        wait_for_ajaximations

        f("#assignment_restrict_file_extensions").click
        # invalid extension type
        f("#assignment_allowed_extensions").send_keys("a" * 256)
        # unchecking Restrict Upload File Types clears the error and allow the form to be submitted
        f("#assignment_restrict_file_extensions").click

        submit_assignment_form

        expect(assignment.reload.submission_types).to eq "online_text_entry,online_upload"
      end
    end

    context "validates group assignment" do
      before do
        @assignment = @course.assignments.create({
                                                   name: "first test assignment",
                                                   assignment_group: @course.assignment_groups.create!(name: "default")
                                                 })
      end

      it "is created before saving", priority: "1" do
        get "/courses/#{@course.id}/assignments/new"
        f("#has_group_category").click
        f(%(span[data-testid="group-set-close"])).click
        submit_assignment_form
        wait_for_ajaximations
        expect(f("#assignment_group_category_id_errors").text).to eq "Please create a group set"
      end

      context "with group sets" do
        before do
          @gc = GroupCategory.create(name: "Group Set}", context: @course)
        end

        it "clears the errors when the user selects a group", priority: "1" do
          get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
          f("#has_group_category").click
          f("#assignment_group_category_id").click
          f('#assignment_group_category_id [value="blank"]').click
          submit_assignment_form
          wait_for_ajaximations
          expect(f("#assignment_group_category_id_errors").text).to eq "Please select a group set for this assignment"
          f('#assignment_group_category_id [value="' + @gc.id.to_s + '"]').click
          wait_for_ajaximations
          expect(f("#assignment_group_category_id_errors").text).to eq ""
        end

        it "clears the errors when the user unchecks and rechecks the group assignment checkbox", priority: "1" do
          get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
          f("#has_group_category").click
          f("#assignment_group_category_id").click
          f('#assignment_group_category_id [value="blank"]').click
          submit_assignment_form
          wait_for_ajaximations
          expect(f("#assignment_group_category_id_errors").text).to eq "Please select a group set for this assignment"
          f("#has_group_category").click # uncheck
          f("#has_group_category").click # check again
          wait_for_ajaximations
          expect(f("#assignment_group_category_id_errors").text).to eq ""
        end
      end
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

      describe "validations" do
        context "file upload" do
          it "shows an error on submit and clears it if the user select a file" do
            get "/courses/#{@course.id}/assignments"
            wait_for_new_page_load { f(".new_assignment").click }
            f("#assignment_name").send_keys("Validation for Annotated Document Submission Type")

            f("#assignment_annotated_document").click
            wait_for_ajaximations

            submit_assignment_form
            expect(f("#online_submission_types\\[student_annotation\\]_errors")).to include_text("This submission type requires a file upload")

            # select attachment from file explorer
            fxpath('//*[@id="annotated_document_chooser_container"]/div/div[1]/ul/li[1]/button').click
            fxpath('//*[@id="annotated_document_chooser_container"]/div/div[1]/ul/li[1]/ul/li/button').click

            expect(f("#online_submission_types\\[student_annotation\\]_errors")).not_to include_text("This submission type requires a file upload")
          end

          it "shows an error on submit and clears it if the user uncheck Student Annotation" do
            get "/courses/#{@course.id}/assignments"
            wait_for_new_page_load { f(".new_assignment").click }
            f("#assignment_name").send_keys("Validation for Annotated Document Submission Type")

            f("#assignment_annotated_document").click
            wait_for_ajaximations

            submit_assignment_form
            expect(f("#online_submission_types\\[student_annotation\\]_errors")).to include_text("This submission type requires a file upload")

            # Uncheck Student Annotation
            f("#assignment_annotated_document").click
            wait_for_ajaximations

            expect(f("#online_submission_types\\[student_annotation\\]_errors")).not_to include_text("This submission type requires a file upload")
          end
        end

        context "usage rights" do
          it "shows an error on submit and clears it on changing usage rights" do
            get "/courses/#{@course.id}/assignments"
            wait_for_new_page_load { f(".new_assignment").click }
            f("#assignment_name").send_keys("Validation for Usage Rights")

            f("#assignment_annotated_document").click
            wait_for_ajaximations

            # select attachment from file explorer
            fxpath('//*[@id="annotated_document_chooser_container"]/div/div[1]/ul/li[1]/button').click
            fxpath('//*[@id="annotated_document_chooser_container"]/div/div[1]/ul/li[1]/ul/li/button').click

            submit_assignment_form
            wait_for_ajaximations

            expect(f("#usage_rights_use_justification_errors")).to include_text("Identifying the usage rights is required")

            f("#usageRightSelector").click
            fxpath('//*[@id="usageRightSelector"]/option[2]').click
            expect(f("#usage_rights_use_justification_errors")).not_to include_text("Identifying the usage rights is required")
          end
        end
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

      it "allows editing the due date even if completely frozen", :ignore_js_errors do
        old_due_at = @frozen_assign.due_at
        run_assignment_edit(@frozen_assign) do
          assign_to_due_date.send_keys(:control, "a", :backspace)
          update_due_date(0, "Sep 20, 2012")
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

    context "with default tool set up" do
      before do
        a = @course.account
        a.settings[:default_assignment_tool_name] = "Test Default Tool"
        a.settings[:default_assignment_tool_url] = "http://lti13testtool.docker/launch"
        a.settings[:default_assignment_tool_button_text] = "Default Tool"
        a.settings[:default_assignment_tool_info_message] = "Click the button above to add content"
        a.save!
      end

      it "shows an error if user saves without configuring the tool" do
        get "/courses/#{@course.id}/assignments/new"
        f("#assignment_submission_type").click
        f('[value="default_external_tool"]').click

        f(".btn-primary[type=submit]").click
        wait_for_ajaximations
        expect(f("#default-tool-launch-button_errors").text).to eq "External Tool URL cannot be left blank"
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

        edit_assignment(assignment.id, points: 5, submit: true)

        expect(assignment.reload.primary_resource_link.custom).to eq(custom_params)
      end

      it "shows an error on submit for an empty External Tool URL" do
        assignment
        get "/courses/#{@course.id}/assignments/#{assignment.id}/edit"
        wait_for_ajaximations

        # clear the external tool url input
        tool.url.each_char { f("#assignment_external_tool_tag_attributes_url").send_keys(:backspace) }
        submit_assignment_form

        expect(f("#external_tool_tag_attributes\\[url\\]_errors")).to include_text("External Tool URL cannot be left blank")
      end

      it "shows an error on submit for an invalid External Tool URL" do
        assignment
        get "/courses/#{@course.id}/assignments/#{assignment.id}/edit"
        wait_for_ajaximations

        # clear the external tool url input
        tool.url.each_char { f("#assignment_external_tool_tag_attributes_url").send_keys(:backspace) }
        # replace with invalid url
        f("#assignment_external_tool_tag_attributes_url").send_keys("invalid")
        submit_assignment_form

        expect(f("#external_tool_tag_attributes\\[url\\]_errors")).to include_text('Enter a valid URL or use "Find" button to search for an external tool')
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
      @course.root_account.enable_feature!(:moderated_grading)
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

    it "validates grader count must be greater than 0 and final grader must be selected" do
      get "/courses/#{@course.id}/assignments/new"

      f("#assignment_name").send_keys("Grader count must be greater than 0")
      f("#assignment_moderated_grading").click
      f("#grader_count").send_keys("\b")
      f("#grader_count").send_keys("0")

      submit_assignment_form

      grader_count_error_msg = f("#grader_count_errors")
      expect(grader_count_error_msg).to include_text("Must have at least one grader")

      final_grader_error_msg = f("#final_grader_id_errors")
      expect(final_grader_error_msg).to include_text("Must select a grader")
    end

    it "validates grader count must be less than MODERATED_GRADING_GRADER_LIMIT" do
      get "/courses/#{@course.id}/assignments/new"

      f("#assignment_name").send_keys("Grader count must be less than a maximum")
      f("#assignment_moderated_grading").click
      f("#grader_count").send_keys("\b")
      f("#grader_count").send_keys("01234567890123456789012")

      submit_assignment_form

      grader_count_error_msg = f("#grader_count_errors")
      expect(grader_count_error_msg).to include_text("Only a maximum of #{Course::MODERATED_GRADING_GRADER_LIMIT} graders can be assigned")
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

  context "with discussion_checkpoints" do
    before :once do
      sub_account = Account.create!(name: "sub account", parent_account: Account.default)
      course_with_teacher({ user: @teacher, active_course: true, active_enrollment: true, account: sub_account })
      sub_account.enable_feature! :discussion_checkpoints

      @checkpointed_discussion = DiscussionTopic.create_graded_topic!(course: @course, title: "checkpointed discussion")
      Checkpoints::DiscussionCheckpointCreatorService.call(
        discussion_topic: @checkpointed_discussion,
        checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
        dates: [{ type: "everyone", due_at: 2.days.from_now }],
        points_possible: 6
      )
      Checkpoints::DiscussionCheckpointCreatorService.call(
        discussion_topic: @checkpointed_discussion,
        checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
        dates: [{ type: "everyone", due_at: 3.days.from_now }],
        points_possible: 7,
        replies_required: 2
      )
    end

    it "does not show points possible and due date fields for checkpointed assignments" do
      user_session(@teacher)

      get "/courses/#{@course.id}/assignments"
      f("div#assignment_#{@checkpointed_discussion.assignment.id} button.al-trigger").click
      f("li a.edit_assignment").click
      expect(f("[data-testid='assignment-name-input']")).not_to be_disabled
      expect(f("[data-testid='points-input']")).to be_disabled
      # Date
      expect(f("#Selectable___0")).to be_disabled
      # Time
      expect(f("#Select___0")).to be_disabled
    end

    it "displays the correct date input fields in the assign to tray" do
      user_session(@teacher)
      get "/courses/#{@course.id}/assignments"

      fj("#assign_#{@checkpointed_discussion.assignment.id}_manage_link").click
      wait_for_ajaximations

      f("#assignment_#{@checkpointed_discussion.assignment.id} .assign-to-link").click
      wait_for_assign_to_tray_spinner

      expect(module_item_assign_to_card.first).not_to contain_css(due_date_input_selector)
      expect(module_item_assign_to_card.first).to contain_css(reply_to_topic_due_date_input_selector)
      expect(module_item_assign_to_card.first).to contain_css(required_replies_due_date_input_selector)
    end
  end
end
