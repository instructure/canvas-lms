# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "../pages/gradebook_page"
require_relative "../pages/gradebook_cells_page"
require_relative "../pages/gradebook_grade_detail_tray_page"
require_relative "../../helpers/gradebook_common"
require_relative "../../helpers/files_common"

describe "Grade Detail Tray:" do
  include_context "in-process server selenium tests"
  include GradebookCommon
  include FilesCommon
  include_context "late_policy_course_setup"

  before(:once) do
    # create course with students, assignments, submissions and grades
    init_course_with_students(2)
    create_course_late_policy
    create_assignments
    make_submissions
    grade_assignments
    @custom_status = CustomGradeStatus.create!(name: "Custom Status", color: "#000000", root_account_id: @course.root_account_id, created_by: @teacher)
    @a5 = @course.assignments.create!(name: "Assignment 5", points_possible: 10, submission_types: "online_text_entry")
    @course.students.first.submissions.find_by(assignment_id: @a5.id).update!(custom_grade_status: @custom_status)
  end

  context "status" do
    before do
      user_session(@teacher)
      Gradebook.visit(@course)
    end

    it "missing submission has missing-radiobutton unselected", priority: "1" do
      Gradebook::Cells.open_tray(@course.students.first, @a2)

      expect(Gradebook::GradeDetailTray.is_radio_button_selected("missing")).to be false
    end

    it "updates status when none-option is selected", priority: "2" do
      Gradebook::Cells.open_tray(@course.students.first, @a2)
      Gradebook::GradeDetailTray.change_status_to("Missing")
      Gradebook::GradeDetailTray.change_status_to("None")

      late_policy_status = @course.students.first.submissions.find_by(assignment_id: @a2.id).late_policy_status

      expect(late_policy_status).to eq "none"
    end

    it "on-time submission has none-radiobutton selected", priority: "1" do
      Gradebook::Cells.open_tray(@course.students.first, @a3)

      expect(Gradebook::GradeDetailTray.is_radio_button_selected("none")).to be true
    end

    it "excused submission has excused-radiobutton selected", priority: "1" do
      Gradebook::Cells.open_tray(@course.students.first, @a4)

      expect(Gradebook::GradeDetailTray.is_radio_button_selected("excused")).to be true
    end

    it "submisison with custom status has custom status radio-button selected" do
      Gradebook::Cells.open_tray(@course.students.first, @a5)

      expect(Gradebook::GradeDetailTray.is_radio_button_selected(@custom_status.id)).to be true
    end

    it "updates status when excused-option is selected", priority: "1" do
      Gradebook::Cells.open_tray(@course.students.first, @a2)
      Gradebook::GradeDetailTray.change_status_to("Excused")

      excuse_status = @course.students.first.submissions.find_by(assignment_id: @a2.id).excused

      expect(excuse_status).to be true
    end

    it "updates status when missing-option is selected", priority: "2" do
      Gradebook::Cells.open_tray(@course.students.first, @a2)
      Gradebook::GradeDetailTray.change_status_to("Missing")

      late_policy_status = @course.students.first.submissions.find_by(assignment_id: @a2.id).late_policy_status

      expect(late_policy_status).to eq "missing"
    end

    it "updates the status when custom status is selected" do
      Gradebook::Cells.open_tray(@course.students.first, @a2)
      Gradebook::GradeDetailTray.change_status_to("Custom Status")
      submission = @course.students.first.submissions.find_by(assignment_id: @a2.id)

      expect(submission.late_policy_status).to be_nil
      expect(submission.custom_grade_status).to eq @custom_status
    end

    it "grade input is saved", priority: "1" do
      Gradebook::Cells.open_tray(@course.students.second, @a3)
      Gradebook::GradeDetailTray.edit_grade(7)

      expect(Gradebook::Cells.get_grade(@course.students.second, @a3)).to eq "7"
    end
  end

  context "late status" do
    before do
      user_session(@teacher)
      Gradebook.visit(@course)
      Gradebook::Cells.open_tray(@course.students.first, @a1)
    end

    it "late submission has late-radiobutton selected", priority: "1" do
      expect(Gradebook::GradeDetailTray.is_radio_button_selected("late")).to be true
    end

    it "late submission has late-by days/hours", priority: "1" do
      late_by_days_value = (@course.students.first.submissions.find_by(assignment_id: @a1.id)
        .seconds_late / 86_400.to_f).round(2)

      expect(Gradebook::GradeDetailTray.fetch_late_by_value.to_f).to eq late_by_days_value
    end

    it "late submission has late penalty", priority: "1" do
      late_penalty_value = "-" + @course.students.first.submissions.find_by(assignment_id: @a1.id).points_deducted.to_s

      # the data from rails and data from ui are not in the same format
      expect(Gradebook::GradeDetailTray.late_penalty_text.to_f.to_s).to eq late_penalty_value
    end

    it "late submission has final grade", priority: "2" do
      final_grade_value = @course.students.first.submissions.find_by(assignment_id: @a1.id).published_grade

      expect(Gradebook::GradeDetailTray.final_grade_text).to eq final_grade_value
    end

    it "updates score when late_by value changes", priority: "1" do
      Gradebook::GradeDetailTray.edit_late_by_input(3)
      final_grade_value = @course.students.first.submissions.find_by(assignment_id: @a1.id).published_grade
      expect(final_grade_value).to eq "60"
      expect(Gradebook::GradeDetailTray.final_grade_text).to eq "60"
      expect(Gradebook::GradeDetailTray.late_penalty_text).to eq "-30"
    end
  end

  context "navigation within tray" do
    before do
      user_session(@teacher)
    end

    context "with default ordering" do
      before do
        Gradebook.visit(@course)
      end

      it "speedgrader link navigates to speedgrader page", priority: "1" do
        Gradebook::Cells.open_tray(@course.students[0], @a1)
        Gradebook::GradeDetailTray.speedgrader_link.click

        expect(driver.current_url).to include "courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@a1.id}"
      end

      it "clicking assignment name navigates to assignment page", priority: "2" do
        Gradebook::Cells.open_tray(@course.students.first, @a1)
        Gradebook::GradeDetailTray.assignment_link(@a1.name).click

        expect(driver.current_url).to include "courses/#{@course.id}/assignments/#{@a1.id}"
      end

      it "assignment right arrow loads the next assignment in the tray", priority: "1" do
        Gradebook::Cells.open_tray(@course.students.first, @a1)
        button = Gradebook::GradeDetailTray.next_assignment_button
        # have to wait for InstUI animations
        keep_trying_until do
          button.click
          true
        end
        expect(Gradebook::GradeDetailTray.assignment_link(@a2.name)).to be_displayed
      end

      it "assignment left arrow loads the previous assignment in the tray", priority: "1" do
        Gradebook::Cells.open_tray(@course.students.first, @a2)
        button = Gradebook::GradeDetailTray.previous_assignment_button
        # have to wait for InstUI animations
        keep_trying_until do
          button.click
          true
        end

        expect(Gradebook::GradeDetailTray.assignment_link(@a1.name)).to be_displayed
      end

      it "left arrow button is not present when leftmost assignment is selected", priority: "2" do
        Gradebook::Cells.open_tray(@course.students.first, @a1)

        expect(Gradebook::GradeDetailTray.submission_tray_full_content)
          .not_to contain_css("#assignment-carousel .left-arrow-button-container button")
      end

      it "right arrow button is not present when rightmost assignment is selected", priority: "2" do
        Gradebook::Cells.open_tray(@course.students.first, @a5)

        expect(Gradebook::GradeDetailTray.submission_tray_full_content)
          .not_to contain_css("#assignment-carousel .right-arrow-button-container button")
      end

      it "student right arrow navigates to next student", priority: "1" do
        Gradebook::Cells.open_tray(@course.students.first, @a1)
        button = Gradebook::GradeDetailTray.next_student_button
        # have to wait for instUI Tray animation
        keep_trying_until do
          button.click
          true
        end
        expect(Gradebook::GradeDetailTray.student_link(@course.students.second.name)).to be_displayed
      end

      it "student left arrow navigates to previous student", priority: "1" do
        Gradebook::Cells.open_tray(@course.students.second, @a1)
        button = Gradebook::GradeDetailTray.previous_student_button
        # have to wait for instUI Tray animation
        keep_trying_until do
          button.click
          true
        end
        expect(Gradebook::GradeDetailTray.student_link(@course.students.first.name)).to be_displayed
      end

      it "first student does not have left arrow", priority: "1" do
        Gradebook::Cells.open_tray(@course.students.first, @a1)

        expect(Gradebook::GradeDetailTray.submission_tray_full_content)
          .not_to contain_css(Gradebook::GradeDetailTray.navigate_to_previous_student_selector)
      end

      it "student name link navigates to student grades page", priority: "2" do
        Gradebook::Cells.open_tray(@course.students.first, @a1)
        Gradebook::GradeDetailTray.student_link(@course.students.first.name).click

        expect(driver.current_url).to include "courses/#{@course.id}/grades/#{@course.students.first.id}"
      end
    end

    context "when the rightmost column is an assignment column" do
      before do
        @teacher.set_preference(:gradebook_column_order, @course.global_id, {
                                  sortType: "custom",
                                  customOrder: [
                                    "assignment_#{@a1.id}",
                                    "assignment_#{@a2.id}",
                                    "assignment_group_#{@a1.assignment_group_id}",
                                    "assignment_#{@a3.id}",
                                    "total_grade",
                                    "assignment_#{@a4.id}"
                                  ]
                                })
        Gradebook.visit(@course)
      end

      it "clicking the left arrow loads the previous assignment in the tray", priority: "2" do
        Gradebook::Cells.open_tray(@course.students.first, @a4)
        button = Gradebook::GradeDetailTray.previous_assignment_button
        # have to wait for instUI Tray animation
        keep_trying_until do
          button.click
          true
        end
        expect(Gradebook::GradeDetailTray.assignment_link(@a3.name)).to be_displayed
      end
    end
  end

  context "comments" do
    let(:comment_1) { "You are late1" }
    let(:comment_2) { "You are also late2" }

    before do
      user_session(@teacher)

      submission_comment_model({ author: @teacher,
                                 submission: @a1.find_or_create_submission(@course.students.first),
                                 comment: comment_1 })
      Gradebook.visit(@course)
    end

    it "add a comment", priority: "1" do
      Gradebook::Cells.open_tray(@course.students.first, @a1)
      Gradebook::GradeDetailTray.add_new_comment(comment_2)

      expect(Gradebook::GradeDetailTray.comment(comment_2)).to be_displayed
    end

    it "delete a comment", priority: "1" do
      skip_if_safari(:alert)
      Gradebook::Cells.open_tray(@course.students.first, @a1)
      Gradebook::GradeDetailTray.delete_comment(comment_1)

      # comment text is in a paragraph element and there is only one comment seeded
      expect(Gradebook::GradeDetailTray.all_comments).not_to contain_css("p")
    end
  end

  context "submit for student" do
    before do
      Account.site_admin.enable_feature!(:proxy_file_uploads)
      teacher_role = Role.get_built_in_role("TeacherEnrollment", root_account_id: Account.default.id)
      RoleOverride.create!(
        permission: "proxy_assignment_submission",
        enabled: true,
        role: teacher_role,
        account: @course.root_account
      )
      @a1.update!(submission_types: "online_upload,online_text_entry")
      file_attachment = attachment_model(content_type: "application/pdf", context: @students.first)
      @submission = @a1.submit_homework(@students.first, submission_type: "online_upload", attachments: [file_attachment])
      @teacher.update!(short_name: "Test Teacher")
      @submission.update!(proxy_submitter: @teacher)
      user_session(@teacher)
      Gradebook.visit(@course)
    end

    it "button is availible for assignments with online uploads" do
      Gradebook::Cells.open_tray(@course.students.first, @a1)
      expect(Gradebook::GradeDetailTray.submit_for_student_button).to be_displayed
    end

    it "modal allows multiple files to be uploaded via the file upload drop" do
      filename1, fullpath1 = get_file("testfile1.txt")
      filename2, fullpath2 = get_file("testfile2.txt")
      Gradebook::Cells.open_tray(@course.students.first, @a1)
      Gradebook::GradeDetailTray.submit_for_student_button.click
      Gradebook::GradeDetailTray.proxy_file_drop.send_keys(fullpath1)
      Gradebook::GradeDetailTray.proxy_file_drop.send_keys(fullpath2)
      expect(f("table[data-testid='proxy_uploaded_files_table']")).to include_text(filename1)
      expect(f("table[data-testid='proxy_uploaded_files_table']")).to include_text(filename2)
      expect(Gradebook::GradeDetailTray.proxy_submit_button).to be_displayed
    end

    it "allows a file to be uploaded via the file upload drop" do
      Gradebook::Cells.open_tray(@course.students.first, @a1)
      expect(Gradebook::GradeDetailTray.proxy_submitter_name.text).to include("Submitted by " + @teacher.short_name)
      expect(Gradebook::GradeDetailTray.proxy_date_time).to be_displayed
    end
  end

  context "final grade override" do
    before do
      @course.update!(allow_final_grade_override: true)
      @course.enable_feature!(:final_grades_override)
      user_session(@teacher)
      Gradebook.visit(@course)
    end

    it "allows a custom grade status to be selected" do
      Gradebook::Cells.edit_override(@students.first, 90.0)
      f(Gradebook::Cells.grade_override_selector(@students.first)).click
      Gradebook::Cells.grade_tray_button.click
      wait_for_ajaximations
      student_enrollment_score = @students.first.enrollments.first.find_score

      expect { Gradebook::GradeDetailTray.change_status_to("Custom Status") }.to change { student_enrollment_score.reload.custom_grade_status }.from(nil).to(@custom_status)
    end
  end

  context "checkpoints" do
    before do
      @course.root_account.enable_feature!(:discussion_checkpoints)

      create_checkpoint_assignment

      user_session(@teacher)
    end

    it "can be graded on Traditional Gradebook using the SubmissionTray" do
      Gradebook.visit(@course)
      Gradebook::Cells.open_tray(@students[0], @checkpoint_assignment)

      reply_to_topic_input = Gradebook::GradeDetailTray.grade_inputs[0]
      required_replies_input = Gradebook::GradeDetailTray.grade_inputs[1]
      current_total = Gradebook::GradeDetailTray.grade_inputs[2]

      Gradebook::GradeDetailTray.edit_grade_for_input(reply_to_topic_input, 3)
      Gradebook::GradeDetailTray.edit_grade_for_input(required_replies_input, 9)

      expect(current_total).to have_attribute("disabled", "true")
      expect(current_total).to have_value("12")

      reply_to_topic_checkpoint = @checkpoint_assignment.sub_assignments.find_by(sub_assignment_tag: "reply_to_topic")
      reply_to_entry_checkpoint = @checkpoint_assignment.sub_assignments.find_by(sub_assignment_tag: "reply_to_entry")

      student0_reply_to_topic_submission = reply_to_topic_checkpoint.submissions.find_by(user_id: @students[0].id)
      student0_reply_to_entry_submission = reply_to_entry_checkpoint.submissions.find_by(user_id: @students[0].id)
      student0_parent_submission = @checkpoint_assignment.submissions.find_by(user_id: @students[0].id)

      expect(student0_reply_to_topic_submission.score).to eq 3
      expect(student0_reply_to_entry_submission.score).to eq 9
      expect(student0_parent_submission.score).to eq 12
    end

    it "shows status selector for each checkpoint and shows Days Late input when selecting Late" do
      Gradebook.visit(@course)
      Gradebook::Cells.open_tray(@students[0], @checkpoint_assignment)

      reply_to_topic_select = f("[data-testid='reply_to_topic-checkpoint-status-select']")
      reply_to_entry_select = f("[data-testid='reply_to_entry-checkpoint-status-select']")

      expect(reply_to_topic_select).to be_displayed
      expect(reply_to_entry_select).to be_displayed

      reply_to_topic_select.click
      fj("span[role='option']:contains('Late')").click

      expect(f("[data-testid='reply_to_topic-checkpoint-time-late-input']")).to be_displayed
    end

    it "changes statuses as expected and persist it" do
      Gradebook.visit(@course)
      Gradebook::Cells.open_tray(@students[0], @checkpoint_assignment)

      reply_to_topic_select = f("[data-testid='reply_to_topic-checkpoint-status-select']")

      reply_to_topic_select.click
      fj("span[role='option']:contains('Late')").click

      reply_to_topic_assignment = @checkpoint_assignment.sub_assignments.find_by(sub_assignment_tag: "reply_to_topic")
      reply_to_topic_submission = reply_to_topic_assignment.submissions.find_by(user: @students[0])

      expect(reply_to_topic_submission.late_policy_status).to eq "late"

      reply_to_topic_time_late_input = f("[data-testid='reply_to_topic-checkpoint-time-late-input']")
      reply_to_topic_time_late_input.send_keys("5")
      reply_to_topic_time_late_input.send_keys(:tab)

      # 5 days * 24 hours * 60 minutes * 60 seconds = 432000
      expect(reply_to_topic_submission.reload.seconds_late_override).to eq 432_000

      reply_to_topic_select.click
      fj("span[role='option']:contains('Excused')").click

      expect(reply_to_topic_submission.reload.excused).to be_truthy
    end

    it "changes custom status as expected and persist it" do
      Gradebook.visit(@course)
      Gradebook::Cells.open_tray(@students[0], @checkpoint_assignment)

      reply_to_topic_select = f("[data-testid='reply_to_topic-checkpoint-status-select']")

      reply_to_topic_select.click
      fj("span[role='option']:contains('Custom Status')").click

      reply_to_topic_assignment = @checkpoint_assignment.sub_assignments.find_by(sub_assignment_tag: "reply_to_topic")
      reply_to_topic_submission = reply_to_topic_assignment.submissions.find_by(user: @students[0])

      expect(reply_to_topic_submission.custom_grade_status_id).to eq @custom_status.id
    end

    context "sub submissions context", :ignore_js_errors do
      it "displays late status with separate late times" do
        # Set late times for each checkpoint
        reply_to_topic = @checkpoint_assignment.sub_assignments.find_by(sub_assignment_tag: "reply_to_topic")
        reply_to_entry = @checkpoint_assignment.sub_assignments.find_by(sub_assignment_tag: "reply_to_entry")

        reply_to_topic.grade_student(@students[0], grade: 3, grader: @teacher)
        reply_to_entry.grade_student(@students[0], grade: 9, grader: @teacher)

        reply_to_topic.submissions.find_by(user: @students[0]).update!(late_policy_status: "late", seconds_late_override: 1.day)
        reply_to_entry.submissions.find_by(user: @students[0]).update!(late_policy_status: "late", seconds_late_override: 2.days)

        Gradebook.visit(@course)
        Gradebook::Cells.open_tray(@students[0], @checkpoint_assignment)

        expect(f("[data-testid='reply_to_topic-checkpoint-status-select']")).to have_attribute("value", "Late")
        expect(f("[data-testid='reply_to_entry-checkpoint-status-select']")).to have_attribute("value", "Late")

        expect(f("[data-testid='reply_to_topic-checkpoint-time-late-input']")).to have_value("1")
        expect(f("[data-testid='reply_to_entry-checkpoint-time-late-input']")).to have_value("2")
      end

      it "displays missing and excused status" do
        reply_to_topic = @checkpoint_assignment.sub_assignments.find_by(sub_assignment_tag: "reply_to_topic")
        reply_to_entry = @checkpoint_assignment.sub_assignments.find_by(sub_assignment_tag: "reply_to_entry")

        reply_to_topic.submissions.find_by(user: @students[0]).update!(late_policy_status: "missing")
        reply_to_entry.submissions.find_by(user: @students[0]).update!(excused: true)

        Gradebook.visit(@course)
        Gradebook::Cells.open_tray(@students[0], @checkpoint_assignment)

        expect(f("[data-testid='reply_to_topic-checkpoint-status-select']")).to have_attribute("value", "Missing")
        expect(f("[data-testid='reply_to_entry-checkpoint-status-select']")).to have_attribute("value", "Excused")
      end

      it "displays extended and none statuses" do
        reply_to_topic = @checkpoint_assignment.sub_assignments.find_by(sub_assignment_tag: "reply_to_topic")
        @checkpoint_assignment.sub_assignments.find_by(sub_assignment_tag: "reply_to_entry")

        reply_to_topic.submissions.find_by(user: @students[0]).update!(late_policy_status: "extended")
        # 'None' status is the default, so we don't need to set it explicitly
        Gradebook.visit(@course)
        Gradebook::Cells.open_tray(@students[0], @checkpoint_assignment)

        expect(f("[data-testid='reply_to_topic-checkpoint-status-select']")).to have_attribute("value", "Extended")
        expect(f("[data-testid='reply_to_entry-checkpoint-status-select']")).to have_attribute("value", "None")
      end

      it "displays statuses correctly when opening different cells" do
        checkpointed_assignment_late = @checkpoint_assignment
        reply_to_entry = checkpointed_assignment_late.sub_assignments.find_by(sub_assignment_tag: "reply_to_entry")
        reply_to_entry.grade_student(@students[0], grade: 9, grader: @teacher)
        reply_to_entry.submissions.find_by(user: @students[0]).update!(late_policy_status: "late", seconds_late_override: 2.days)

        checkpointed_assignment_excused = create_checkpoint_assignment
        reply_to_entry = checkpointed_assignment_excused.sub_assignments.find_by(sub_assignment_tag: "reply_to_entry")
        reply_to_entry.submissions.find_by(user: @students[0]).update!(excused: true)

        Gradebook.visit(@course)
        Gradebook::Cells.open_tray(@students[0], checkpointed_assignment_late)
        expect(f("[data-testid='reply_to_topic-checkpoint-status-select']")).to have_attribute("value", "None")
        expect(f("[data-testid='reply_to_entry-checkpoint-status-select']")).to have_attribute("value", "Late")
        expect(f("[data-testid='reply_to_entry-checkpoint-time-late-input']")).to have_value("2")

        Gradebook::GradeDetailTray.click_close_tray_button
        Gradebook::Cells.open_tray(@students[0], checkpointed_assignment_excused)
        expect(f("[data-testid='reply_to_topic-checkpoint-status-select']")).to have_attribute("value", "None")
        expect(f("[data-testid='reply_to_entry-checkpoint-status-select']")).to have_attribute("value", "Excused")
      end

      it "persists data when clicking the speedgraded link", :ignore_js_errors do
        discussion_topic = DiscussionTopic.create_graded_topic!(course: @course, title: "late discussion")
        due_at = 1.week.ago

        Checkpoints::DiscussionCheckpointCreatorService.call(
          discussion_topic:,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "everyone", due_at: }],
          points_possible: 20
        )

        Checkpoints::DiscussionCheckpointCreatorService.call(
          discussion_topic:,
          checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
          dates: [{ type: "everyone", due_at: }],
          points_possible: 10,
          replies_required: 1
        )

        entry = discussion_topic.discussion_entries.create!(user: @students[0])
        sub_entry = discussion_topic.discussion_entries.build
        sub_entry.parent_id = entry.id
        sub_entry.user_id = @students[0].id
        sub_entry.save!

        late_assignment = Assignment.last
        user_session(@teacher)
        Gradebook.visit(@course)
        Gradebook::Cells.open_tray(@students[0], late_assignment)
        reply_to_topic_input = Gradebook::GradeDetailTray.grade_inputs[0]
        required_replies_input = Gradebook::GradeDetailTray.grade_inputs[1]
        Gradebook::GradeDetailTray.edit_grade_for_input(reply_to_topic_input, 10)
        Gradebook::GradeDetailTray.edit_grade_for_input(required_replies_input, 10)
        Gradebook::GradeDetailTray.speedgrader_link.click
        expect(f("[data-testid='reply_to_topic-checkpoint-status-select']")).to have_attribute("value", "Late")
        expect(f("[data-testid='reply_to_entry-checkpoint-status-select']")).to have_attribute("value", "Late")
      end
    end
  end
end
