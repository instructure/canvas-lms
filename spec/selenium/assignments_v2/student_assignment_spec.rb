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

require_relative "page_objects/student_assignment_page_v2"
require_relative "../common"
require_relative "../rcs/pages/rce_next_page"

describe "as a student" do
  specs_require_sharding
  include RCENextPage
  include_context "in-process server selenium tests"

  context "on assignments 2 page" do
    before(:once) do
      Account.default.enable_feature!(:assignments_2_student)
      @course = course_factory(name: "course", active_course: true)
      @student = student_in_course(name: "Student", course: @course, enrollment_state: :active).user
      @teacher = teacher_in_course(name: "teacher", course: @course, enrollment_state: :active).user
    end

    context "assignment details with restrict_quantitative_data truthy" do
      before :once do
        # truthy feature flag
        Account.default.enable_feature! :restrict_quantitative_data

        # truthy setting
        Account.default.settings[:restrict_quantitative_data] = { value: true, locked: true }
        Account.default.save!
        @course.restrict_quantitative_data = true
        @course.save!
      end

      context "not submitted" do
        it "does not show points possible for points grading_type" do
          skip "FOO-3525 (10/6/2023)"
          assignment = @course.assignments.create!(
            name: "assignment",
            due_at: 5.days.ago,
            points_possible: 10,
            submission_types: "online_text_entry",
            grading_type: "points"
          )

          user_session(@student)
          StudentAssignmentPageV2.visit(@course, assignment)
          wait_for_ajaximations

          expect(f("body")).not_to contain_jqcss("span:contains('#{assignment.points_possible}'))")
        end
      end

      context "graded" do
        it "shows grade as letter_grade for points grading type" do
          assignment = @course.assignments.create!(
            name: "assignment",
            due_at: 5.days.ago,
            points_possible: 10,
            submission_types: "online_text_entry",
            grading_type: "points"
          )

          assignment.grade_student(@student, grade: "9", grader: @teacher)
          user_session(@student)
          StudentAssignmentPageV2.visit(@course, assignment)
          wait_for_ajaximations
          expect(f("span.selected-submission-grade").text).to include("A−")
          expect(f("span.selected-submission-grade").text).not_to include("9")
          expect(f("span[data-testid='grade-display']").text).to include("A−")
          expect(f("span[data-testid='grade-display']").text).not_to include("9")
        end

        context "0 points possible" do
          it "shows no grade when score is 0 or less for points" do
            assignment = @course.assignments.create!(
              name: "assignment",
              due_at: 5.days.ago,
              points_possible: 0,
              submission_types: "online_text_entry",
              grading_type: "points"
            )

            assignment.grade_student(@student, grade: "0", grader: @teacher)
            user_session(@student)
            StudentAssignmentPageV2.visit(@course, assignment)
            wait_for_ajaximations
            expect(f("body")).not_to contain_css("span.selected-submission-grade")
            expect(f("span[data-testid='grade-display']").text).to eq ""
          end

          it "shows A when score is greater than 0 for quantitative assignments" do
            assignment = @course.assignments.create!(
              name: "assignment",
              due_at: 5.days.ago,
              points_possible: 0,
              submission_types: "online_text_entry",
              grading_type: "points"
            )
            assignment.submit_homework(@student, { body: "blah" })
            assignment.grade_student(@student, grade: "1", grader: @teacher)
            user_session(@student)
            StudentAssignmentPageV2.visit(@course, assignment)
            wait_for_ajaximations
            expect(f("span.selected-submission-grade").text).to eq "Attempt 1 Score:\nA"
            expect(f("span[data-testid='grade-display']").text).to eq "A"
          end

          it "shows complete when score is greater than 0 for pass_fail assignments" do
            assignment = @course.assignments.create!(
              name: "assignment",
              due_at: 5.days.ago,
              points_possible: 0,
              submission_types: "online_text_entry",
              grading_type: "pass_fail"
            )
            assignment.submit_homework(@student, { body: "blah" })
            assignment.grade_student(@student, grade: "complete", grader: @teacher)
            user_session(@student)
            StudentAssignmentPageV2.visit(@course, assignment)
            wait_for_ajaximations
            expect(f("span.selected-submission-grade").text).to eq "Attempt 1 Score:\nComplete"
            expect(f("span[data-testid='grade-display']").text).to eq "Complete"
          end

          it "uses the coerced score to letter_grade when score is greater than 0 for letter_grade assignments" do
            assignment = @course.assignments.create!(
              name: "assignment",
              due_at: 5.days.ago,
              points_possible: 0,
              submission_types: "online_text_entry",
              grading_type: "letter_grade"
            )
            assignment.submit_homework(@student, { body: "blah" })
            assignment.grade_student(@student, grade: "1", grader: @teacher)
            user_session(@student)
            StudentAssignmentPageV2.visit(@course, assignment)
            wait_for_ajaximations
            # showing A means it used the coerced score, without coercion, it would show "1"
            expect(f("span.selected-submission-grade").text).to eq "Attempt 1 Score:\nA"
            expect(f("span[data-testid='grade-display']").text).to eq "A"
          end
        end

        it "shows 0 grade as F for points grading type" do
          assignment = @course.assignments.create!(
            name: "assignment",
            due_at: 5.days.ago,
            points_possible: 10,
            submission_types: "online_text_entry",
            grading_type: "points"
          )

          assignment.grade_student(@student, grade: "0", grader: @teacher)
          user_session(@student)
          StudentAssignmentPageV2.visit(@course, assignment)
          wait_for_ajaximations
          expect(f("span.selected-submission-grade").text).to include("F")
          expect(f("span.selected-submission-grade").text).not_to include("0")
          expect(f("span[data-testid='grade-display']").text).to include("F")
          expect(f("span[data-testid='grade-display']").text).not_to include("0")
        end

        it "shows Excused when student is excused" do
          assignment = @course.assignments.create!(
            name: "assignment",
            due_at: 5.days.ago,
            points_possible: 10,
            submission_types: "online_text_entry",
            grading_type: "points"
          )

          assignment.grade_student(@student, excused: true, grader: @teacher)
          user_session(@student)
          StudentAssignmentPageV2.visit(@course, assignment)
          wait_for_ajaximations
          expect(f("body")).not_to contain_css("span.selected-submission-grade")
          expect(f("span[data-testid='grade-display']").text).to include("Excused")
        end

        it "shows grade as letter_grade for percent grading type" do
          assignment = @course.assignments.create!(
            name: "assignment",
            due_at: 5.days.ago,
            points_possible: 10,
            submission_types: "online_text_entry",
            grading_type: "percent"
          )

          assignment.grade_student(@student, grade: "9", grader: @teacher)
          user_session(@student)
          StudentAssignmentPageV2.visit(@course, assignment)
          wait_for_ajaximations
          # making sure 9 does not show implicitly makes sure 90% does not show as well
          expect(f("span.selected-submission-grade").text).to include("A−")
          expect(f("span.selected-submission-grade").text).not_to include("9")
          expect(f("span[data-testid='grade-display']").text).to include("A−")
          expect(f("span[data-testid='grade-display']").text).not_to include("9")
        end

        it "shows grade as letter_grade for gpa_scale grading type" do
          assignment = @course.assignments.create!(
            name: "assignment",
            due_at: 5.days.ago,
            points_possible: 10,
            submission_types: "online_text_entry",
            grading_type: "gpa_scale"
          )

          assignment.grade_student(@student, grade: "9", grader: @teacher)
          user_session(@student)
          StudentAssignmentPageV2.visit(@course, assignment)
          wait_for_ajaximations
          # making sure 9 does not show implicitly makes sure 90% does not show as well
          expect(f("span.selected-submission-grade").text).to include("A−")
          expect(f("span[data-testid='grade-display']").text).to include("A−")
        end

        it "still shows grade as letter_grade for letter_grade grading type" do
          assignment = @course.assignments.create!(
            name: "assignment",
            due_at: 5.days.ago,
            points_possible: 10,
            submission_types: "online_text_entry",
            grading_type: "letter_grade"
          )

          assignment.grade_student(@student, grade: "9", grader: @teacher)
          user_session(@student)
          StudentAssignmentPageV2.visit(@course, assignment)
          wait_for_ajaximations
          # making sure 9 does not show implicitly makes sure 90% does not show as well
          expect(f("span.selected-submission-grade").text).to include("A−")
          expect(f("span[data-testid='grade-display']").text).to include("A−")
        end

        it "still shows grade as complete/incomplete for pass_fail grading type" do
          assignment = @course.assignments.create!(
            name: "assignment",
            due_at: 5.days.ago,
            points_possible: 10,
            submission_types: "online_text_entry",
            grading_type: "pass_fail"
          )

          assignment.grade_student(@student, grade: "pass", grader: @teacher)
          user_session(@student)
          StudentAssignmentPageV2.visit(@course, assignment)
          wait_for_ajaximations
          # making sure 9 does not show implicitly makes sure 90% does not show as well
          expect(f("span.selected-submission-grade").text).to include("Complete")
          expect(f("span[data-testid='grade-display']").text).to include("Complete")
        end
      end
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
        expect(StudentAssignmentPageV2.submission_workflow_tracker).to include_text("In Progress")
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

      it "changes the submit assignment button to new attempt button after the first submission is made" do
        expect(StudentAssignmentPageV2.new_attempt_button).to be_displayed
      end

      it "shows submission workflow tracker status as submitted after the student submits" do
        expect(StudentAssignmentPageV2.submission_workflow_tracker).to include_text("Submitted")
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
        expect(StudentAssignmentPageV2.submission_workflow_tracker).to include_text("Review Feedback")
      end

      it "shows Cancel Attempt X button when a subsequent submission is in progress but not submitted" do
        StudentAssignmentPageV2.new_attempt_button.click

        expect(StudentAssignmentPageV2.cancel_attempt_button).to be_displayed
      end

      it "cancels attempt when Cancel Attempt button is selected during subsequent attempt" do
        StudentAssignmentPageV2.new_attempt_button.click
        expect(StudentAssignmentPageV2.submission_workflow_tracker).to include_text("In Progress")
        StudentAssignmentPageV2.cancel_attempt_button.click

        expect(StudentAssignmentPageV2.submission_workflow_tracker).to include_text("Review Feedback")
      end
    end

    context "0 points possible assignments" do
      it "shows score/0 for points type assignments" do
        assignment = @course.assignments.create!(
          name: "assignment",
          due_at: 5.days.from_now,
          points_possible: 0,
          submission_types: "online_text_entry"
        )
        assignment.submit_homework(@student, { body: "blah" })
        assignment.grade_student(@student, grade: "4", grader: @teacher)

        user_session(@student)
        StudentAssignmentPageV2.visit(@course, assignment)
        wait_for_ajaximations
        expect(f("span.selected-submission-grade").text).to eq "Attempt 1 Score:\n4/0"
        expect(f("span[data-testid='grade-display']").text).to eq "4/0 Points"
      end

      it "simply shows the score for letter-grade assignments" do
        assignment = @course.assignments.create!(
          name: "assignment",
          due_at: 5.days.from_now,
          points_possible: 0,
          submission_types: "online_text_entry",
          grading_type: "letter_grade"
        )
        assignment.submit_homework(@student, { body: "blah" })
        assignment.grade_student(@student, grade: "9", grader: @teacher)

        user_session(@student)
        StudentAssignmentPageV2.visit(@course, assignment)
        wait_for_ajaximations
        expect(f("span.selected-submission-grade").text).to eq "Attempt 1 Score:\n9"
        expect(f("span[data-testid='grade-display']").text).to eq "9"
      end

      it "shows N/A once for complete/incomplete assignments" do
        assignment = @course.assignments.create!(
          name: "assignment",
          due_at: 5.days.from_now,
          points_possible: 0,
          submission_types: "online_text_entry",
          grading_type: "pass_fail"
        )
        assignment.submit_homework(@student, { body: "blah" })
        assignment.grade_student(@student, grade: "9", grader: @teacher)

        user_session(@student)
        StudentAssignmentPageV2.visit(@course, assignment)
        wait_for_ajaximations
        expect(f("span.selected-submission-grade").text).to eq "Attempt 1 Score:\nN/A"
        expect(f("span[data-testid='grade-display']").text).to eq ""
      end

      it "shows simply the percentage for percent assignments" do
        assignment = @course.assignments.create!(
          name: "assignment",
          due_at: 5.days.from_now,
          points_possible: 0,
          submission_types: "online_text_entry",
          grading_type: "percent"
        )
        assignment.submit_homework(@student, { body: "blah" })
        assignment.grade_student(@student, grade: "9", grader: @teacher)

        user_session(@student)
        StudentAssignmentPageV2.visit(@course, assignment)
        wait_for_ajaximations
        expect(f("span.selected-submission-grade").text).to eq "Attempt 1 Score:\n9%"
        expect(f("span[data-testid='grade-display']").text).to eq "9%"
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

    context "peer reviews" do
      before(:once) do
        Account.default.enable_feature!(:peer_reviews_for_a2)
        @student1 = student_in_course(name: "Student 1", course: @course, enrollment_state: :active).user
        @student2 = student_in_course(name: "Student 2", course: @course, enrollment_state: :active).user
        @student3 = student_in_course(name: "Student 3", course: @course, enrollment_state: :active).user

        @peer_review_assignment = assignment_model({
                                                     course: @course,
                                                     peer_reviews: true,
                                                     automatic_peer_reviews: false,
                                                     points_possible: 10,
                                                     submission_types: "online_text_entry"
                                                   })

        @peer_review_assignment.assign_peer_review(@student1, @student3)
      end

      before do
        user_session(@student1)
      end

      it "shows a modal reminding the student that they have 2 peer reviews and 1 is availible after submitting" do
        @peer_review_assignment.assign_peer_review(@student1, @student2)
        @peer_review_assignment.submit_homework(
          @student3,
          body: "student 3 attempt",
          submission_type: "online_text_entry"
        )
        StudentAssignmentPageV2.visit(@course, @peer_review_assignment)
        wait_for_ajaximations
        wait_for_tiny(StudentAssignmentPageV2.text_entry_area)
        StudentAssignmentPageV2.create_text_entry_draft("hello")
        wait_for_tiny(StudentAssignmentPageV2.text_entry_area)
        StudentAssignmentPageV2.submit_button_enabled
        StudentAssignmentPageV2.submit_assignment

        expect(StudentAssignmentPageV2.peer_review_header_text).to include("Your work has been submitted.\nCheck back later to view feedback.")
        expect(StudentAssignmentPageV2.peer_review_sub_header_text).to include("You have 2 Peer Reviews to complete.\nPeer submissions ready for review: 1")
      end

      it "shows a modal reminding the student that they have 2 peer reviews and 0 are availible after submitting" do
        @peer_review_assignment.assign_peer_review(@student1, @student2)
        StudentAssignmentPageV2.visit(@course, @peer_review_assignment)
        wait_for_ajaximations
        wait_for_tiny(StudentAssignmentPageV2.text_entry_area)
        StudentAssignmentPageV2.create_text_entry_draft("hello")
        wait_for_tiny(StudentAssignmentPageV2.text_entry_area)
        StudentAssignmentPageV2.submit_button_enabled
        StudentAssignmentPageV2.submit_assignment

        expect(StudentAssignmentPageV2.peer_review_header_text).to include("Your work has been submitted.\nCheck back later to view feedback.")
        expect(StudentAssignmentPageV2.peer_review_sub_header_text).to include("You have 2 Peer Reviews to complete.\nPeer submissions ready for review: 0")
        expect(StudentAssignmentPageV2.peer_review_next_button).to be_disabled
      end

      it "allows the student to navigate to assigned peer review through the reminder modal after submitting" do
        @peer_review_assignment.assign_peer_review(@student1, @student2)
        @peer_review_assignment.submit_homework(
          @student3,
          body: "student 3 attempt",
          submission_type: "online_text_entry"
        )
        StudentAssignmentPageV2.visit(@course, @peer_review_assignment)
        wait_for_ajaximations

        wait_for_tiny(StudentAssignmentPageV2.text_entry_area)
        StudentAssignmentPageV2.create_text_entry_draft("hello")
        wait_for_tiny(StudentAssignmentPageV2.text_entry_area)
        StudentAssignmentPageV2.submit_button_enabled
        StudentAssignmentPageV2.submit_assignment
        StudentAssignmentPageV2.peer_review_next_button.click

        expect(StudentAssignmentPageV2.assignment_sub_header).to include_text("Peer: Student 3")
        expect(StudentAssignmentPageV2.comment_container).to include_text("Add a comment to complete your peer review. You will only see comments written by you.")
        expect(StudentAssignmentPageV2.attempt_tab).to include_text("student 3 attempt")
      end

      it "allows the student to complete a peer review without a rubric by adding a comment" do
        @peer_review_assignment.assign_peer_review(@student1, @student2)
        @peer_review_assignment.submit_homework(
          @student3,
          body: "student 3 attempt",
          submission_type: "online_text_entry"
        )
        StudentAssignmentPageV2.visit(@course, @peer_review_assignment)
        wait_for_ajaximations

        wait_for_tiny(StudentAssignmentPageV2.text_entry_area)
        StudentAssignmentPageV2.create_text_entry_draft("hello")
        wait_for_tiny(StudentAssignmentPageV2.text_entry_area)
        StudentAssignmentPageV2.submit_button_enabled
        StudentAssignmentPageV2.submit_assignment
        StudentAssignmentPageV2.peer_review_next_button.click
        StudentAssignmentPageV2.leave_a_comment("great job!")

        expect(StudentAssignmentPageV2.comment_container).to include_text("Your peer review is complete!")
        expect(StudentAssignmentPageV2.comment_container).to include_text("great job!")
      end

      it "after completing a peer review the student is reminded that they still have one more to complete but it is not availible yet" do
        @peer_review_assignment.assign_peer_review(@student1, @student2)
        @peer_review_assignment.submit_homework(
          @student3,
          body: "student 3 attempt",
          submission_type: "online_text_entry"
        )
        StudentAssignmentPageV2.visit(@course, @peer_review_assignment)
        wait_for_ajaximations

        wait_for_tiny(StudentAssignmentPageV2.text_entry_area)
        StudentAssignmentPageV2.create_text_entry_draft("hello")
        wait_for_tiny(StudentAssignmentPageV2.text_entry_area)
        StudentAssignmentPageV2.submit_button_enabled
        StudentAssignmentPageV2.submit_assignment
        StudentAssignmentPageV2.peer_review_next_button.click
        StudentAssignmentPageV2.leave_a_comment("great job!")

        expect(StudentAssignmentPageV2.peer_review_header_text).to include("You have 1 more Peer Review to complete.")
        expect(StudentAssignmentPageV2.peer_review_sub_header_text).to include("The submission is not available just yet.\nPlease check back soon.")
        expect(StudentAssignmentPageV2.peer_review_next_button).to be_disabled
      end

      it "after completing all assigned peer reviews the student is shown a modal that they have completed all reviews for this assignment" do
        @peer_review_assignment.submit_homework(
          @student3,
          body: "student 3 attempt",
          submission_type: "online_text_entry"
        )
        StudentAssignmentPageV2.visit(@course, @peer_review_assignment)
        wait_for_ajaximations

        wait_for_tiny(StudentAssignmentPageV2.text_entry_area)
        StudentAssignmentPageV2.create_text_entry_draft("hello")
        wait_for_tiny(StudentAssignmentPageV2.text_entry_area)
        StudentAssignmentPageV2.submit_button_enabled
        StudentAssignmentPageV2.submit_assignment
        StudentAssignmentPageV2.peer_review_next_button.click
        StudentAssignmentPageV2.leave_a_comment("great job!")

        expect(StudentAssignmentPageV2.peer_review_header_text).to include("You have completed your Peer Reviews!")
      end

      it "allows student to view peer reviewer and teacher comments in feedback tray" do
        @peer_review_assignment.assign_peer_review(@student1, @student2)
        @submission = @peer_review_assignment.submit_homework(
          @student1,
          body: "student 1 attempt",
          submission_type: "online_text_entry"
        )

        @peer_review_assignment.submit_homework(
          @student2,
          body: "student 2 attempt",
          submission_type: "online_text_entry"
        )

        @peer_review_assignment.submit_homework(
          @student3,
          body: "student 3 attempt",
          submission_type: "online_text_entry"
        )

        @submission.add_comment(author: @student2, comment: "peer review comment from student 2")
        @submission.add_comment(author: @student3, comment: "peer review comment from student 3")
        @submission.add_comment(author: @teacher, comment: "teacher comment")
        StudentAssignmentPageV2.visit(@course, @peer_review_assignment)

        expect(StudentAssignmentPageV2.comment_container).to include_text("Student 2")
        expect(StudentAssignmentPageV2.comment_container).to include_text("peer review comment from student 2")
        expect(StudentAssignmentPageV2.comment_container).to include_text("Student 3")
        expect(StudentAssignmentPageV2.comment_container).to include_text("peer review comment from student 3")
        expect(StudentAssignmentPageV2.comment_container).to include_text("teacher")
        expect(StudentAssignmentPageV2.comment_container).to include_text("teacher comment")
      end

      context "anonymous peer review" do
        before(:once) do
          @peer_review_assignment.update!(anonymous_peer_reviews: true)
        end

        it "anonymizes reviewee when completing a review on an assignment with anonymous peer reviews enabled" do
          @peer_review_assignment.submit_homework(
            @student3,
            body: "anonymous attempt",
            submission_type: "online_text_entry"
          )
          StudentAssignmentPageV2.visit(@course, @peer_review_assignment)
          wait_for_ajaximations

          wait_for_tiny(StudentAssignmentPageV2.text_entry_area)
          StudentAssignmentPageV2.create_text_entry_draft("hello")
          wait_for_tiny(StudentAssignmentPageV2.text_entry_area)
          StudentAssignmentPageV2.submit_button_enabled
          StudentAssignmentPageV2.submit_assignment
          StudentAssignmentPageV2.peer_review_next_button.click

          expect(StudentAssignmentPageV2.assignment_sub_header).to include_text("Peer: Anonymous student")
          expect(StudentAssignmentPageV2.attempt_tab).to include_text("anonymous attempt")
        end

        it "allows student to view anonymous peer reviewer and non-anonymous teacher comments in feedback tray" do
          @peer_review_assignment.assign_peer_review(@student1, @student2)
          @submission = @peer_review_assignment.submit_homework(
            @student1,
            body: "student 1 attempt",
            submission_type: "online_text_entry"
          )

          @peer_review_assignment.submit_homework(
            @student3,
            body: "student 2 attempt",
            submission_type: "online_text_entry"
          )

          @submission.add_comment(author: @student3, comment: "peer review comment from student 2")
          @submission.add_comment(author: @teacher, comment: "teacher comment")
          StudentAssignmentPageV2.visit(@course, @peer_review_assignment)

          expect(StudentAssignmentPageV2.comment_container).to include_text("Anonymous")
          expect(StudentAssignmentPageV2.comment_container).to include_text("peer review comment from student 2")
          expect(StudentAssignmentPageV2.comment_container).to include_text("teacher")
          expect(StudentAssignmentPageV2.comment_container).to include_text("teacher comment")
        end
      end

      context "with rubric" do
        before(:once) do
          rubric_model
          @association = @rubric.associate_with(@peer_review_assignment, @course, purpose: "grading", use_for_grading: true)
        end

        it "shows a modal reminding the student that they have 2 peer reviews and 1 is availible after submitting" do
          @peer_review_assignment.assign_peer_review(@student1, @student2)
          @peer_review_assignment.submit_homework(
            @student3,
            body: "student 3 attempt",
            submission_type: "online_text_entry"
          )
          StudentAssignmentPageV2.visit(@course, @peer_review_assignment)
          wait_for_ajaximations

          wait_for_tiny(StudentAssignmentPageV2.text_entry_area)
          StudentAssignmentPageV2.create_text_entry_draft("hello")
          wait_for_tiny(StudentAssignmentPageV2.text_entry_area)
          StudentAssignmentPageV2.submit_button_enabled
          StudentAssignmentPageV2.submit_assignment

          expect(StudentAssignmentPageV2.peer_review_header_text).to include("Your work has been submitted.\nCheck back later to view feedback.")
          expect(StudentAssignmentPageV2.peer_review_sub_header_text).to include("You have 2 Peer Reviews to complete.\nPeer submissions ready for review: 1")
        end

        it "shows a modal reminding the student that they have 2 peer reviews and 0 are availible after submitting" do
          @peer_review_assignment.assign_peer_review(@student1, @student2)
          StudentAssignmentPageV2.visit(@course, @peer_review_assignment)
          wait_for_ajaximations

          wait_for_tiny(StudentAssignmentPageV2.text_entry_area)
          StudentAssignmentPageV2.create_text_entry_draft("hello")
          wait_for_tiny(StudentAssignmentPageV2.text_entry_area)
          StudentAssignmentPageV2.submit_button_enabled
          StudentAssignmentPageV2.submit_assignment

          expect(StudentAssignmentPageV2.peer_review_header_text).to include("Your work has been submitted.\nCheck back later to view feedback.")
          expect(StudentAssignmentPageV2.peer_review_sub_header_text).to include("You have 2 Peer Reviews to complete.\nPeer submissions ready for review: 0")
          expect(StudentAssignmentPageV2.peer_review_next_button).to be_disabled
        end

        it "allows the student to navigate to assigned peer review through the reminder modal after submitting" do
          @peer_review_assignment.assign_peer_review(@student1, @student2)
          @peer_review_assignment.submit_homework(
            @student3,
            body: "student 3 attempt",
            submission_type: "online_text_entry"
          )
          StudentAssignmentPageV2.visit(@course, @peer_review_assignment)
          wait_for_ajaximations

          wait_for_tiny(StudentAssignmentPageV2.text_entry_area)
          StudentAssignmentPageV2.create_text_entry_draft("hello")
          wait_for_tiny(StudentAssignmentPageV2.text_entry_area)
          StudentAssignmentPageV2.submit_button_enabled
          StudentAssignmentPageV2.submit_assignment
          StudentAssignmentPageV2.peer_review_next_button.click

          expect(StudentAssignmentPageV2.assignment_sub_header).to include_text("Peer: Student 3")
          expect(StudentAssignmentPageV2.fill_out_rubric_toggle).to include_text("Fill Out Rubric")
          expect(StudentAssignmentPageV2.rubric_tab).to include_text("Fill out the rubric below after reviewing the student submission to complete this review.")
        end

        it "allows the student to complete a peer review by completing the rubric and submitting" do
          @peer_review_assignment.assign_peer_review(@student1, @student2)
          @peer_review_assignment.submit_homework(
            @student3,
            body: "student 3 attempt",
            submission_type: "online_text_entry"
          )
          StudentAssignmentPageV2.visit(@course, @peer_review_assignment)
          wait_for_ajaximations

          wait_for_tiny(StudentAssignmentPageV2.text_entry_area)
          StudentAssignmentPageV2.create_text_entry_draft("hello")
          wait_for_tiny(StudentAssignmentPageV2.text_entry_area)
          StudentAssignmentPageV2.submit_button_enabled
          StudentAssignmentPageV2.submit_assignment
          StudentAssignmentPageV2.peer_review_next_button.click
          StudentAssignmentPageV2.select_rubric_criterion("Good")
          StudentAssignmentPageV2.submit_peer_review_button.click

          expect(StudentAssignmentPageV2.peer_review_header_text).to include("You have 1 more Peer Review to complete.")
          expect(StudentAssignmentPageV2.peer_review_sub_header_text).to include("The submission is not available just yet.\nPlease check back soon.")
          expect(StudentAssignmentPageV2.peer_review_next_button).to be_disabled
        end

        it "after completing all assigned peer reviews the student is shown a modal that they have completed all reviews for this assignment" do
          @peer_review_assignment.submit_homework(
            @student3,
            body: "student 3 attempt",
            submission_type: "online_text_entry"
          )
          StudentAssignmentPageV2.visit(@course, @peer_review_assignment)
          wait_for_ajaximations

          wait_for_tiny(StudentAssignmentPageV2.text_entry_area)
          StudentAssignmentPageV2.create_text_entry_draft("hello")
          wait_for_tiny(StudentAssignmentPageV2.text_entry_area)
          StudentAssignmentPageV2.submit_button_enabled
          StudentAssignmentPageV2.submit_assignment
          StudentAssignmentPageV2.peer_review_next_button.click
          StudentAssignmentPageV2.select_rubric_criterion("Good")
          StudentAssignmentPageV2.submit_peer_review_button.click

          expect(StudentAssignmentPageV2.peer_review_header_text).to include("You have completed your Peer Reviews!")
        end

        it "allows student to view peer reviewer and teacher rubric assessments via the dropdown menu" do
          @peer_review_assignment.assign_peer_review(@student1, @student2)
          @submission = @peer_review_assignment.submit_homework(
            @student1,
            body: "student 1 attempt",
            submission_type: "online_text_entry"
          )

          @peer_review_assignment.submit_homework(
            @student2,
            body: "student 2 attempt",
            submission_type: "online_text_entry"
          )

          @peer_review_assignment.submit_homework(
            @student3,
            body: "student 3 attempt",
            submission_type: "online_text_entry"
          )
          @association.assess({
                                user: @student1,
                                assessor: @teacher,
                                artifact: @peer_review_assignment.find_or_create_submission(@student1),
                                assessment: {
                                  assessment_type: "grading",
                                  criterion_crit1: {
                                    points: 10,
                                    comments: "teacher comment",
                                  }
                                }
                              })
          @association.assess({
                                user: @student1,
                                assessor: @student2,
                                artifact: @peer_review_assignment.find_or_create_submission(@student1),
                                assessment: {
                                  assessment_type: "peer_review",
                                  criterion_crit1: {
                                    points: 5,
                                    comments: "student 2 comment",
                                  }
                                }
                              })
          @association.assess({
                                user: @student1,
                                assessor: @student3,
                                artifact: @peer_review_assignment.find_or_create_submission(@student1),
                                assessment: {
                                  assessment_type: "peer_review",
                                  criterion_crit1: {
                                    points: 0,
                                    comments: "student 3 comment",
                                  }
                                }
                              })
          StudentAssignmentPageV2.visit(@course, @peer_review_assignment)

          expect(StudentAssignmentPageV2.rubric_comments).to include_text("teacher comment")
          expect(StudentAssignmentPageV2.rubric_rating_selected).to include_text("10 pts")

          StudentAssignmentPageV2.select_grader("Student 3 (Student)")
          expect(StudentAssignmentPageV2.rubric_comments).to include_text("student 3 comment")
          expect(StudentAssignmentPageV2.rubric_rating_selected).to include_text("0 pts")

          StudentAssignmentPageV2.select_grader("Student 2 (Student)")
          expect(StudentAssignmentPageV2.rubric_comments).to include_text("student 2 comment")
          expect(StudentAssignmentPageV2.rubric_rating_selected).to include_text("5 pts")
        end

        context "anonymous peer review" do
          before(:once) do
            @peer_review_assignment.update!(anonymous_peer_reviews: true)
          end

          it "allows student to view anonymous peer reviewer rubric assessments via the dropdown menu" do
            @peer_review_assignment.assign_peer_review(@student1, @student2)
            @submission = @peer_review_assignment.submit_homework(
              @student1,
              body: "student 1 attempt",
              submission_type: "online_text_entry"
            )
            @peer_review_assignment.submit_homework(
              @student2,
              body: "student 2 attempt",
              submission_type: "online_text_entry"
            )
            @association.assess({
                                  user: @student1,
                                  assessor: @student2,
                                  artifact: @peer_review_assignment.find_or_create_submission(@student1),
                                  assessment: {
                                    assessment_type: "peer_review",
                                    criterion_crit1: {
                                      points: 5,
                                      comments: "student 2 comment",
                                    }
                                  }
                                })
            StudentAssignmentPageV2.visit(@course, @peer_review_assignment)

            StudentAssignmentPageV2.select_grader("Anonymous")
            expect(StudentAssignmentPageV2.rubric_comments).to include_text("student 2 comment")
            expect(StudentAssignmentPageV2.rubric_rating_selected).to include_text("5 pts")
          end
        end
      end

      context "group peer review" do
        before(:once) do
          gc = GroupCategory.create(name: "gc", context: @course)
          group = @course.groups.create!(group_category: gc)
          group.users << @student1
          group.users << @student2
          @peer_review_assignment.update!(group_category_id: gc.id)
        end

        it "allows the student to complete a group peer review without a rubric by adding a comment" do
          @peer_review_assignment.assign_peer_review(@student1, @student2)
          @peer_review_assignment.submit_homework(
            @student3,
            body: "student 3 attempt",
            submission_type: "online_text_entry"
          )
          StudentAssignmentPageV2.visit(@course, @peer_review_assignment)
          wait_for_ajaximations

          wait_for_tiny(StudentAssignmentPageV2.text_entry_area)
          StudentAssignmentPageV2.create_text_entry_draft("hello")
          wait_for_tiny(StudentAssignmentPageV2.text_entry_area)
          StudentAssignmentPageV2.submit_button_enabled
          StudentAssignmentPageV2.submit_assignment
          StudentAssignmentPageV2.peer_review_next_button.click
          StudentAssignmentPageV2.leave_a_comment("great job!")

          expect(StudentAssignmentPageV2.comment_container).to include_text("Your peer review is complete!")
          expect(StudentAssignmentPageV2.comment_container).to include_text("great job!")
        end

        it "allows the student to complete a group peer review with a rubric by completing the rubric and submitting", skip: "flaky" do
          rubric_model
          @association = @rubric.associate_with(@peer_review_assignment, @course, purpose: "grading", use_for_grading: true)
          @peer_review_assignment.assign_peer_review(@student1, @student2)
          @peer_review_assignment.submit_homework(
            @student3,
            body: "student 3 attempt",
            submission_type: "online_text_entry"
          )
          StudentAssignmentPageV2.visit(@course, @peer_review_assignment)
          wait_for_ajaximations

          wait_for_tiny(StudentAssignmentPageV2.text_entry_area)
          StudentAssignmentPageV2.create_text_entry_draft("hello")
          wait_for_tiny(StudentAssignmentPageV2.text_entry_area)
          StudentAssignmentPageV2.submit_button_enabled
          StudentAssignmentPageV2.submit_assignment
          StudentAssignmentPageV2.peer_review_next_button.click
          StudentAssignmentPageV2.select_rubric_criterion("Good")
          StudentAssignmentPageV2.submit_peer_review_button.click

          expect(StudentAssignmentPageV2.peer_review_header_text).to include("You have 1 more Peer Review to complete.")
          expect(StudentAssignmentPageV2.peer_review_next_button).to be_displayed
        end
      end
    end
  end
end
