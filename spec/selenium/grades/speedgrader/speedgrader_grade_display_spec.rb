# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative "../../common"
require_relative "../../helpers/speed_grader_common"
require_relative "../../helpers/gradebook_common"
require_relative "../pages/speedgrader_page"

describe "speed grader - grade display" do
  include_context "in-process server selenium tests"
  include SpeedGraderCommon
  include_context "late_policy_course_setup"
  include GradebookCommon

  context "grade display" do
    let(:points) { 10.0 }
    let(:grade) { 3.0 }

    before do
      course_with_teacher_logged_in
      create_and_enroll_students(2)
      @assignment = @course.assignments.create(name: "assignment", points_possible: points)
    end

    it "displays the score on the sidebar", priority: "1" do
      @assignment.grade_student(@students[0], grade:, grader: @teacher)
      Speedgrader.visit(@course.id, @assignment.id)
      expect(Speedgrader.grade_value).to eq grade.to_int.to_s
    end

    it "displays total number of graded assignments to students", priority: "1" do
      @assignment.grade_student(@students[0], grade:, grader: @teacher)
      Speedgrader.visit(@course.id, @assignment.id)
      expect(Speedgrader.fraction_graded).to include_text("1/2")
    end

    it "displays average submission grade for total assignment submissions", priority: "1" do
      @assignment.grade_student(@students[0], grade:, grader: @teacher)
      Speedgrader.visit(@course.id, @assignment.id)
      average = (grade / points * 100).to_int
      expect(Speedgrader.average_grade).to include_text("#{grade.to_int} / #{points.to_int} (#{average}%)")
    end
  end

  context "late_policy_pills" do
    before(:once) do
      # create course with students, assignments, submissions and grades
      init_course_with_students(1)
      create_course_late_policy
      create_assignments
      make_submissions
      grade_assignments
    end

    before do
      user_session(@teacher)
    end

    it "shows late pill" do
      Speedgrader.visit(@course.id, @a1.id)
      expect(Speedgrader.submission_status_pill("late")).to be_displayed
    end

    it "shows late deduction and final grade" do
      Speedgrader.visit(@course.id, @a1.id)

      late_penalty_value = "-" + @course.students[0].submissions.find_by(assignment_id: @a1.id).points_deducted.to_s
      final_grade_value = @course.students[0].submissions.find_by(assignment_id: @a1.id).published_grade

      # the data from rails and data from ui are not in the same format
      expect(Speedgrader.late_points_deducted_text.to_f.to_s).to eq late_penalty_value
      expect(Speedgrader.final_late_policy_grade_text).to eq final_grade_value
    end

    it "removes missing pill after being graded" do
      Speedgrader.visit(@course.id, @a2.id)

      expect(find_all_with_jquery(".submission-missing-pill:contains('missing')").length).to eq 0
    end
  end

  context "missing policy pills when graded" do
    before do
      init_course_with_students(3)
      create_assignments
      user_session(@teacher)
    end

    it "removes missing pill when teacher navigates away from student" do
      Speedgrader.visit(@course.id, @a2.id)
      Speedgrader.grade_input.send_keys(70)
      Speedgrader.click_next_student_btn
      Speedgrader.click_next_or_prev_student("prev")

      expect(find_all_with_jquery(".submission-missing-pill:contains('missing')").length).to eq 0
    end
  end

  context "keyboard shortcuts" do
    let(:first_grade) { 5 }
    let(:last_grade) { 10 }

    before do
      course_with_teacher_logged_in
      create_and_enroll_students(2)
      @assignment = @course.assignments.create!(
        title: "assignment",
        grading_type: "points",
        points_possible: 100,
        due_at: 1.day.since(now),
        submission_types: "online_text_entry"
      )
      # submit assignemnt with different content for each student
      @assignment.submit_homework(@course.students.first, body: "submitting my homework")
      @assignment.submit_homework(@course.students.second, body: "submitting my different homework")
      # as a teacher grade the assignment with different scores
      @assignment.grade_student(@course.students.first, grade: first_grade, grader: @teacher)
      @assignment.grade_student(@course.students.second, grade: last_grade, grader: @teacher)
      Speedgrader.visit(@course.id, @assignment.id)
    end

    it "shows correct student and submission using command+Home/command+end shortcut" do
      student_select = f("#combo_box_container .ui-selectmenu .ui-selectmenu-item-header")
      driver.action.double_click(student_select).perform
      driver.action.key_down(:meta).key_down(:end).key_up(:meta).key_up(:end).perform
      last_student = f("#combo_box_container .ui-selectmenu .ui-selectmenu-item-header").text
      last_grade = f("#grade_container #grading-box-extended").attribute("value")

      expect(last_grade).to eql(last_grade.to_s)
      expect(last_student).to eql(@course.students.last.name)

      student_select = f("#combo_box_container .ui-selectmenu .ui-selectmenu-item-header")
      driver.action.double_click(student_select).perform
      driver.action.key_down(:meta).key_down(:home).key_up(:meta).key_up(:end).perform
      first_student = f("#combo_box_container .ui-selectmenu .ui-selectmenu-item-header").text
      first_grade = f("#grade_container #grading-box-extended").attribute("value")

      expect(first_grade).to eql(first_grade.to_s)
      expect(first_student).to eql(@course.students.first.name)
    end
  end
end
