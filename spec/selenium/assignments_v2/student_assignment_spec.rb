# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

require_relative "./page_objects/student_assignment_page_v2"
require_relative "../common"
require_relative "../rcs/pages/rce_next_page"

describe "as a student" do
  include RCENextPage
  include_context "in-process server selenium tests"

  context "on assignments 2 page" do
    before(:once) do
      Account.default.enable_feature!(:assignments_2_student)
      @course = course_factory(name: "course", active_course: true)
      @student = student_in_course(name: "Student", course: @course, enrollment_state: :active).user
      @teacher = teacher_in_course(name: "teacher", course: @course, enrollment_state: :active).user
    end

    context "assignment details" do
      before(:once) do
        @assignment = @course.assignments.create!(
          name: "assignment",
          due_at: 5.days.ago,
          points_possible: 10,
          submission_types: "online_text_entry"
        )
        rubric_model(
          title: "rubric",
          data: [{
            description: "Some criterion",
            points: 5,
            id: "crit1",
            ratings: [{ description: "Good", points: 5, id: "rat1", criterion_id: "crit1" }]
          }],
          description: "new rubric description"
        )
        @rubric.associate_with(@assignment, @course, purpose: "grading", use_for_grading: false)
      end

      before do
        user_session(@student)
        StudentAssignmentPageV2.visit(@course, @assignment)
        wait_for_ajaximations
      end

      it "shows submission workflow tracker status as Inprogress with no submission" do
        expect(StudentAssignmentPageV2.submission_workflow_tracker).to include_text("IN PROGRESS")
      end

      it "shows assignment title" do
        expect(StudentAssignmentPageV2.assignment_title(@assignment.title)).to_not be_nil
      end

      it "shows details toggle" do
        expect(StudentAssignmentPageV2.details_toggle).to be_displayed
      end

      it "shows rubric toggle" do
        expect(StudentAssignmentPageV2.rubric_toggle).to be_displayed
      end

      it "shows missing pill when assignment is late with no submission" do
        expect(StudentAssignmentPageV2.missing_pill).to be_displayed
      end

      it "shows assignment due date" do
        expect(StudentAssignmentPageV2.due_date_css(@assignment.due_at)).to_not be_nil
      end

      it "shows how many points possible the assignment is worth" do
        expect(StudentAssignmentPageV2.points_possible_css(@assignment.points_possible)).to_not be_nil
      end
    end

    context "submitted assignments" do
      before(:once) do
        @assignment = @course.assignments.create!(
          name: "assignment",
          due_at: 5.days.ago,
          points_possible: 10,
          submission_types: "online_upload"
        )
        @file_attachment = attachment_model(content_type: "application/pdf", context: @student)
        @assignment.submit_homework(@student, submission_type: "online_upload", attachments: [@file_attachment])
      end

      before do
        user_session(@student)
        StudentAssignmentPageV2.visit(@course, @assignment)
        wait_for_ajaximations
      end

      it "shows late pill when assignment is late with at least one submission" do
        expect(StudentAssignmentPageV2.late_pill).to be_displayed
      end

      it "changes the submit assignment button to try again button after the first submission is made" do
        expect(StudentAssignmentPageV2.try_again_button).to be_displayed
      end

      it "shows submission workflow tracker status as submitted after the student submits" do
        expect(StudentAssignmentPageV2.submission_workflow_tracker).to include_text("SUBMITTED")
      end

      it "shows the file name of the submitted file and an option to download" do
        expect(StudentAssignmentPageV2.attempt_tab).to include_text(@file_attachment.filename)
        expect(StudentAssignmentPageV2.attempt_tab).to include_text("Download")
      end
    end

    context "graded assignments" do
      before(:once) do
        @assignment = @course.assignments.create!(
          name: "assignment",
          due_at: 5.days.from_now,
          points_possible: 10,
          submission_types: "online_text_entry"
        )
        @assignment.submit_homework(@student, { body: "blah" })
        @assignment.grade_student(@student, grade: "4", grader: @teacher)
      end

      before do
        user_session(@student)
        StudentAssignmentPageV2.visit(@course, @assignment)
        wait_for_ajaximations
      end

      it "shows submission workflow tracker status as review feedback after the student is graded" do
        expect(StudentAssignmentPageV2.submission_workflow_tracker).to include_text("REVIEW FEEDBACK")
      end

      it "shows Cancel Attempt X button when a subsequent submission is in progress but not submitted" do
        StudentAssignmentPageV2.try_again_button.click

        expect(StudentAssignmentPageV2.cancel_attempt_button).to be_displayed
      end

      it "cancels attempt when Cancel Attempt button is selected during subsequent attempt" do
        StudentAssignmentPageV2.try_again_button.click
        expect(StudentAssignmentPageV2.submission_workflow_tracker).to include_text("IN PROGRESS")
        StudentAssignmentPageV2.cancel_attempt_button.click

        expect(StudentAssignmentPageV2.submission_workflow_tracker).to include_text("REVIEW FEEDBACK")
      end
    end

    context "text assignments" do
      before(:once) do
        @assignment = @course.assignments.create!(
          name: "text assignment",
          due_at: 5.days.ago,
          points_possible: 10,
          submission_types: "online_text_entry"
        )
      end

      before do
        user_session(@student)
        StudentAssignmentPageV2.visit(@course, @assignment)
        wait_for_tiny(StudentAssignmentPageV2.text_entry_area)
      end

      it "can be submitted", custom_timeout: 30 do
        StudentAssignmentPageV2.create_text_entry_draft("Hello")
        wait_for_tiny(StudentAssignmentPageV2.text_entry_area)

        StudentAssignmentPageV2.submit_button_enabled
        StudentAssignmentPageV2.submit_assignment

        expect(f("body")).to include_text("Hello")
      end

      it "is able to be saved as a draft", custom_timeout: 30 do
        StudentAssignmentPageV2.create_text_entry_draft("Hello")
        wait_for_tiny(StudentAssignmentPageV2.text_entry_area)

        in_frame tiny_rce_ifr_id do
          expect(f("body")).to include_text("Hello")
        end

        expect(StudentAssignmentPageV2.footer).to include_text("Draft Saved")
        refresh_page
        wait_for_tiny(StudentAssignmentPageV2.text_entry_area)

        in_frame tiny_rce_ifr_id do
          expect(f("body")).to include_text("Hello")
        end
      end
    end

    context "url assignments" do
      before(:once) do
        @assignment = @course.assignments.create!(
          name: "text assignment",
          due_at: 5.days.ago,
          points_possible: 10,
          submission_types: "online_url"
        )
      end

      before do
        user_session(@student)
        StudentAssignmentPageV2.visit(@course, @assignment)
        wait_for_ajaximations
      end

      it "can to be submitted" do
        url_text = "www.google.com"
        StudentAssignmentPageV2.create_url_draft(url_text)
        StudentAssignmentPageV2.submit_assignment

        expect(StudentAssignmentPageV2.url_submission_link).to include_text(url_text)
      end

      it "can be saved as a draft" do
        url_text = "www.google.com"
        StudentAssignmentPageV2.create_url_draft(url_text)

        # This is to wait for the submit button to appear so that we know the draft
        # has been saved. We are not clicking the button here.
        StudentAssignmentPageV2.submit_button

        refresh_page
        expect(StudentAssignmentPageV2.url_text_box.attribute("value")).to include(url_text)
      end
    end

    context "moduleSequenceFooter" do
      before do
        @assignment = @course.assignments.create!(submission_types: "online_upload")

        # add items to module
        @module = @course.context_modules.create!(name: "My Module")
        @item_before = @module.add_item(type: "assignment", id: @course.assignments.create!(title: "assignment BEFORE this one").id)
        @module.add_item(type: "assignment", id: @assignment.id)
        @item_after = @module.add_item(type: "assignment", id: @course.assignments.create!(title: "assignment AFTER this one").id)

        user_session(@student)
        StudentAssignmentPageV2.visit(@course, @assignment)
        wait_for_ajaximations
      end

      it "shows the module sequence footer" do
        expect(f("[data-testid='previous-assignment-btn']")).to have_attribute("href", "/courses/#{@course.id}/modules/items/#{@item_before.id}")
        expect(f("[data-testid='next-assignment-btn']")).to have_attribute("href", "/courses/#{@course.id}/modules/items/#{@item_after.id}")
      end
    end

    context "media assignments" do
      before(:once) do
        @assignment = @course.assignments.create!(
          name: "media assignment",
          due_at: 5.days.ago,
          points_possible: 10,
          submission_types: "media_recording"
        )
      end

      before do
        stub_kaltura
        user_session(@student)
        StudentAssignmentPageV2.visit(@course, @assignment)
        wait_for_ajaximations
      end

      it "can open the record media modal for submission" do
        scroll_to(StudentAssignmentPageV2.open_record_media_modal_button)
        StudentAssignmentPageV2.open_record_media_modal_button.click

        expect(StudentAssignmentPageV2.record_media_modal_panel).to be_displayed
      end

      it "can open the upload media modal for submission" do
        scroll_to(StudentAssignmentPageV2.open_upload_media_modal_button)
        StudentAssignmentPageV2.open_upload_media_modal_button.click

        expect(StudentAssignmentPageV2.upload_media_modal_panel).to be_displayed
      end
    end

    context "file upload assignments" do
      before(:once) do
        @assignment = @course.assignments.create!(
          name: "file upload assignment",
          due_at: 5.days.ago,
          points_possible: 10,
          submission_types: "online_upload"
        )
      end

      before do
        @filename, @fullpath, @data = get_file("testfile1.txt")
        user_session(@student)
        StudentAssignmentPageV2.visit(@course, @assignment)
        wait_for_ajaximations
      end

      it "can be saved as a draft with attached files" do
        StudentAssignmentPageV2.file_input.send_keys(@fullpath)

        expect(StudentAssignmentPageV2.uploaded_files_table).to include_text(@filename)
        refresh_page
        wait_for_ajaximations

        expect(StudentAssignmentPageV2.uploaded_files_table).to include_text(@filename)
      end

      it "can be submitted with a file attached" do
        StudentAssignmentPageV2.file_input.send_keys(@fullpath)
        StudentAssignmentPageV2.submit_assignment
        wait_for_ajaximations

        expect(StudentAssignmentPageV2.attempt_tab).to include_text(@filename)
      end
    end

    context "proxy submitted assignment" do
      before do
        @assignment = @course.assignments.create!(
          name: "proxy upload assignment",
          due_at: 5.days.ago,
          points_possible: 10,
          submission_types: "online_upload"
        )
        Account.site_admin.enable_feature!(:proxy_file_uploads)
        teacher_role = Role.get_built_in_role("TeacherEnrollment", root_account_id: Account.default.id)
        RoleOverride.create!(
          permission: "proxy_assignment_submission",
          enabled: true,
          role: teacher_role,
          account: @course.root_account
        )
        file_attachment = attachment_model(content_type: "application/pdf", context: @student)
        @submission = @assignment.submit_homework(@student, submission_type: "online_upload", attachments: [file_attachment])
        @teacher.update!(short_name: "Test Teacher")
        @submission.update!(proxy_submitter: @teacher)
        user_session(@student)
        StudentAssignmentPageV2.visit(@course, @assignment)
        wait_for_ajaximations
      end

      it "submission workflow tracker identifies the proxy submitter" do
        expect(StudentAssignmentPageV2.submission_workflow_tracker).to include_text("by " + @teacher.short_name)
      end
    end

    context "mark as done" do
      before(:once) do
        @assignment = @course.assignments.create!(
          name: "mark as done assignment",
          due_at: 5.days.ago,
          points_possible: 10,
          submission_types: "on_paper"
        )
        @module = @course.context_modules.create!(name: "Module 1")
        @tag = @module.add_item({ id: @assignment.id, type: "assignment" })
        @module.completion_requirements = { @tag.id => { type: "must_mark_done" } }
        @module.save!
      end

      before do
        user_session(@student)
        StudentAssignmentPageV2.visit(@course, @assignment)
        wait_for_ajaximations
      end

      it "allows student to select and deselct mark as done button in the assignment footer" do
        expect(StudentAssignmentPageV2.mark_as_done_toggle).to include_text("Mark as done")
        StudentAssignmentPageV2.mark_as_done_toggle.click
        expect(StudentAssignmentPageV2.mark_as_done_toggle).to include_text("Done")
        StudentAssignmentPageV2.mark_as_done_toggle.click
        expect(StudentAssignmentPageV2.mark_as_done_toggle).to include_text("Mark as done")
      end
    end

    context "turnitin" do
      before(:once) do
        @turnitin_assignment = @course.assignments.create!(
          submission_types: "online_url",
          turnitin_enabled: true
        )
      end

      before do
        user_session(@student)
        StudentAssignmentPageV2.visit(@course, @turnitin_assignment)
        wait_for_ajaximations
      end

      it "displays similarity pledge checkbox and disables submit button until checked" do
        StudentAssignmentPageV2.create_url_draft("www.google.com")

        expect(StudentAssignmentPageV2.similarity_pledge).to include_text("This assignment submission is my own, original work")
        expect(StudentAssignmentPageV2.submit_button).to be_disabled

        scroll_to(StudentAssignmentPageV2.similarity_pledge)
        StudentAssignmentPageV2.similarity_pledge.click

        expect(StudentAssignmentPageV2.submit_button).to_not be_disabled
      end
    end
  end
end
