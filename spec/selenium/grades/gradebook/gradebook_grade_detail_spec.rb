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
end
