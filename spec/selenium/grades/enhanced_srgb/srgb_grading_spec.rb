# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

require_relative "../../helpers/gradebook_common"
require_relative "../pages/enhanced_srgb_page"
require_relative "../setup/gradebook_setup"
require_relative "../pages/gradebook_grade_detail_tray_page"

describe "Screenreader Gradebook grading" do
  include_context "in-process server selenium tests"
  include_context "reusable_gradebook_course"
  include GradebookCommon
  include GradebookSetup

  let(:course_setup) do
    enroll_teacher_and_students
    assignment_1
    assignment_2
    assignment_2.update!(due_at: 2.days.ago, submission_types: "online_text_entry")
    assignment_3
    assignment_4
    student_submission
  end

  let(:login_to_srgb) do
    user_session(teacher)
    EnhancedSRGB.visit(test_course.id)
    EnhancedSRGB.select_student(student)
  end

  let(:proxy_submit) do
    assignment_1.update!(submission_types: "online_upload")
    file_attachment = attachment_model(content_type: "application/pdf", context: student)
    submission = assignment_1.submit_homework(student, submission_type: "online_upload", attachments: [file_attachment])
    teacher.update!(short_name: "Test Teacher")
    submission.update!(proxy_submitter: teacher)
  end

  let(:proxy_permission) do
    Account.site_admin.enable_feature!(:proxy_file_uploads)
    teacher_role = Role.get_built_in_role("TeacherEnrollment", root_account_id: Account.default.id)
    RoleOverride.create!(
      permission: "proxy_assignment_submission",
      enabled: true,
      role: teacher_role,
      account: @course.root_account
    )
  end

  context "in Grades section" do
    before do
      course_setup
      login_to_srgb
    end

    it "displays correct Grade for label on assignments" do
      EnhancedSRGB.select_assignment(assignment_1)

      expect(EnhancedSRGB.grade_for_label).to include_text("Grade for User - Points Assignment")
    end

    it "displays correct Grade for: label on next assignment" do
      EnhancedSRGB.select_assignment(assignment_4)
      EnhancedSRGB.next_assignment_button.click

      expect(EnhancedSRGB.grade_for_label).to include_text("Grade for User - Percent Assignment")
    end

    it "displays correct points for graded by Points" do
      EnhancedSRGB.select_assignment(assignment_1)
      EnhancedSRGB.grade_srgb_assignment(EnhancedSRGB.main_grade_input, 8)
      EnhancedSRGB.tab_out_of_input(EnhancedSRGB.main_grade_input)

      expect(EnhancedSRGB.main_grade_input).to have_value("8")
    end

    it "displays a flash message when an invalid grade is given and preserves the missing tag" do
      EnhancedSRGB.select_assignment(assignment_2)
      EnhancedSRGB.grade_srgb_assignment(EnhancedSRGB.main_grade_input, "Invalid Grade")
      EnhancedSRGB.tab_out_of_input(EnhancedSRGB.main_grade_input)

      expect(f(".flashalert-message")).to include_text("Invalid Grade")
      expect(EnhancedSRGB.submission_status_pill).to include_text("MISSING")
    end

    it "does not grade student when tabing over the grade input without editing" do
      EnhancedSRGB.select_assignment(assignment_2)
      EnhancedSRGB.main_grade_input.click
      EnhancedSRGB.tab_out_of_input(EnhancedSRGB.main_grade_input)

      expect(EnhancedSRGB.submission_status_pill).to be_displayed
      expect(EnhancedSRGB.main_grade_input).to have_value("-")
    end

    it "excuses student when grade input is 'Excused'" do
      EnhancedSRGB.select_assignment(assignment_1)
      EnhancedSRGB.main_grade_input.clear
      EnhancedSRGB.grade_srgb_assignment(EnhancedSRGB.main_grade_input, "Excused")
      EnhancedSRGB.tab_out_of_input(EnhancedSRGB.main_grade_input)

      expect(EnhancedSRGB.excuse_checkbox.attribute("checked")).to be_truthy
      expect(EnhancedSRGB.main_grade_input).to have_value("Excused")
    end

    it "displays correct points for graded by Percent" do
      EnhancedSRGB.select_assignment(assignment_2)
      EnhancedSRGB.grade_srgb_assignment(EnhancedSRGB.main_grade_input, 8)
      EnhancedSRGB.tab_out_of_input(EnhancedSRGB.main_grade_input)

      expect(EnhancedSRGB.main_grade_input).to have_value("80%")
    end

    it "displays correct points for graded by Complete/Incomplete" do
      EnhancedSRGB.select_assignment(assignment_3)
      click_option(EnhancedSRGB.pass_fail_grade_select, "Complete")
      EnhancedSRGB.tab_out_of_input(EnhancedSRGB.pass_fail_grade_select)

      expect(EnhancedSRGB.out_of_text).to include_text("10 out of 10")
    end

    it "displays correct points for graded by Letter Grade" do
      EnhancedSRGB.select_assignment(assignment_4)
      EnhancedSRGB.grade_srgb_assignment(EnhancedSRGB.main_grade_input, 8)
      EnhancedSRGB.tab_out_of_input(EnhancedSRGB.main_grade_input)

      expect(EnhancedSRGB.main_grade_input).to have_value("B−")
    end

    it "displays submission details modal with correct grade" do
      EnhancedSRGB.select_assignment(assignment_1)
      EnhancedSRGB.grade_srgb_assignment(EnhancedSRGB.main_grade_input, 8)
      EnhancedSRGB.tab_out_of_input(EnhancedSRGB.main_grade_input)
      EnhancedSRGB.submission_details_button.click

      expect(EnhancedSRGB.submission_details_assignment_name).to include_text(assignment_1.name)
      expect(EnhancedSRGB.submission_details_grade_input).to have_value("8")
    end

    it "updates grade in submission details modal" do
      EnhancedSRGB.select_assignment(assignment_2)
      EnhancedSRGB.grade_srgb_assignment(EnhancedSRGB.main_grade_input, 8)
      EnhancedSRGB.tab_out_of_input(EnhancedSRGB.main_grade_input)
      EnhancedSRGB.submission_details_button.click
      # change grade from 8 to 10 in the assignment details modal
      EnhancedSRGB.submission_details_grade_input.clear
      replace_content(EnhancedSRGB.submission_details_grade_input, 10)
      EnhancedSRGB.submission_details_submit_button.click

      expect(EnhancedSRGB.main_grade_input).to have_value("100%")
    end
  end

  context "displays warning" do
    before do
      course_setup
    end

    it "on late submissions" do
      login_to_srgb
      EnhancedSRGB.select_assignment(assignment_1)

      expect(EnhancedSRGB.submission_status_pill).to include_text("LATE")
      expect(EnhancedSRGB.submission_late_penalty_label).to include_text("Late Penalty")
      expect(EnhancedSRGB.late_penalty_final_grade_label).to include_text("Final Grade")
    end

    it "on missing submissions" do
      assignment_1.submissions.find_by(user: student).update!(late_policy_status: "missing")
      login_to_srgb
      EnhancedSRGB.select_assignment(assignment_1)
      expect(EnhancedSRGB.submission_status_pill).to include_text("MISSING")
    end

    it "on dropped assignments" do
      # create an assignment group with drop lowest 1 score rule
      EnhancedSRGB.drop_lowest(test_course, 1)

      # grade a few assignments with one really low grade
      assignment_1.grade_student(student, grade: 3, grader: teacher)
      assignment_2.grade_student(student, grade: 10, grader: teacher)

      login_to_srgb
      EnhancedSRGB.select_assignment(assignment_1)

      # indicates assignment_1 was dropped
      expect(EnhancedSRGB.dropped_message).to include_text("This grade is currently dropped for this student.")
    end

    it "on resubmitted assignments" do
      # grade assignment
      assignment_1.grade_student(student, grade: 8, grader: teacher)

      # resubmit as student
      Timecop.travel(1.hour.from_now) do
        assignment_1.submit_homework(
          student,
          submission_type: "online_text_entry",
          body: "re-submitting!"
        )
      end

      login_to_srgb
      EnhancedSRGB.select_assignment(assignment_1)

      # indicates assignment_1 was resubmitted
      expect(f(".resubmitted_assignment_label")).to include_text("This assignment has been resubmitted")

      # grade the assignment again
      EnhancedSRGB.grade_srgb_assignment(EnhancedSRGB.main_grade_input, 10)
      EnhancedSRGB.tab_out_of_input(EnhancedSRGB.main_grade_input)

      # warning should be removed
      expect(f("#content")).not_to contain_css(".resubmitted_assignment_label")
    end
  end

  context "with grading periods" do
    before do
      term_name = "First Term"
      create_grading_periods(term_name)
      add_teacher_and_student
      associate_course_to_term(term_name)
      user_session(@teacher)
    end

    it "assignment in ended gp should be gradable" do
      assignment = @course.assignments.create!(due_at: 13.days.ago, title: "assign in ended")
      EnhancedSRGB.visit(@course.id)
      EnhancedSRGB.select_grading_period(@gp_ended.title)
      EnhancedSRGB.select_student(@student)
      EnhancedSRGB.select_assignment(assignment)
      EnhancedSRGB.enter_grade(8)

      expect(EnhancedSRGB.current_grade).to eq "8"
      expect(Submission.where(assignment_id: assignment.id, user_id: @student.id).first.grade).to eq("8")
    end

    it "assignment in closed gp should not be gradable" do
      assignment = @course.assignments.create!(due_at: 18.days.ago, title: "assign in closed")
      EnhancedSRGB.visit(@course.id)
      EnhancedSRGB.select_grading_period(@gp_closed.title)
      EnhancedSRGB.select_student(@student)
      EnhancedSRGB.select_assignment(assignment)

      expect(EnhancedSRGB.grading_enabled?).to be false
      expect(Submission.not_placeholder.where(assignment_id: assignment.id, user_id: @student.id).first).to be_nil
    end
  end

  context "submit for student" do
    before do
      enroll_teacher_and_students
      proxy_permission
      assignment_1.update!(submission_types: "online_upload")
    end

    it "displays submit for student button for file upload assignments" do
      login_to_srgb
      EnhancedSRGB.select_assignment(assignment_1)

      expect(EnhancedSRGB.submit_for_student_button).to include_text("Submit for Student")
    end

    it "displays the submitter's identity for proxy submissions" do
      proxy_submit
      login_to_srgb
      EnhancedSRGB.select_assignment(assignment_1)

      expect(EnhancedSRGB.proxy_submitter_label).to include_text("Submitted by Test Teacher")
    end
  end
end
