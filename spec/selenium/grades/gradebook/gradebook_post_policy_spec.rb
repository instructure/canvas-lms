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

require_relative "../../common"
require_relative "../pages/gradebook_page"
require_relative "../pages/gradebook/settings"
require_relative "../pages/student_grades_page"
require_relative "../pages/gradebook_cells_page"
require_relative "../pages/gradebook_grade_detail_tray_page"

describe "Gradebook Post Policy" do
  include_context "in-process server selenium tests"

  # all tests skipped due to flakiness; see the referenced ticket
  before { skip } # EVAL-3613

  before :once do
    # course
    @course_with_manual_post = course_with_teacher(
      course_name: "Post Policy Course",
      active_course: true,
      active_enrollment: true,
      name: "Dedicated Teacher1",
      active_user: true
    ).course
    @teacher1 = @teacher
    # second course with post manually
    @course_with_auto_post = course_with_teacher(
      course_name: "Post Policy Course Manually",
      active_course: true,
      active_enrollment: true,
      name: "Dedicated Teacher2",
      active_user: true
    ).course
    @teacher2 = @teacher
    @course_with_manual_post.default_post_policy.update!(post_manually: true)
    @course_with_auto_post.default_post_policy.update!(post_manually: false)

    # sections
    @section1 = @course_with_manual_post.course_sections.first
    @section2 = @course_with_manual_post.course_sections.create!(name: "Section 2")
    # students
    @section_one_students = create_users_in_course(@course_with_manual_post, 2, return_type: :record, name_prefix: "Purple", section: @section1)
    @section_two_students = create_users_in_course(@course_with_manual_post, 2, return_type: :record, name_prefix: "Indigo", section: @section2)
    @course_two_students = create_users_in_course(@course_with_auto_post, 2, return_type: :record, name_prefix: "Red")
    @students = @section_one_students.dup
    @students.concat(@section_two_students)
    # assignment
    @manual_assignment = @course_with_manual_post.assignments.create!(
      title: "post policy assignment",
      submission_types: "online_text_entry",
      grading_type: "points",
      points_possible: 10
    )

    @auto_assignment = @course_with_auto_post.assignments.create!(
      title: "post policy assignment2",
      submission_types: "online_text_entry",
      grading_type: "points",
      points_possible: 10
    )
  end

  before do
    user_session(@teacher1)
    Gradebook.visit(@course_with_manual_post)
  end

  context do
    before :once do
      @submissions = @students.map do |student|
        @manual_assignment.grade_student(student, grade: 8, grader: @teacher1)
      end.flatten
    end

    context "when post everyone" do
      before do
        Gradebook.manually_post_grades(@manual_assignment, "Everyone")
      end

      it "post grades option disabled" do
        Gradebook.click_assignment_header_menu(@manual_assignment.id)
        expect(Gradebook.grades_posted_option).to be_disabled
      end

      it "students can see grade", priority: "1" do
        verify_grade_displayed_on_student_grade_page(@section_one_students.first, "8", @manual_assignment, @course_with_manual_post)
        verify_grade_displayed_on_student_grade_page(@section_two_students.first, "8", @manual_assignment, @course_with_manual_post)
      end
    end

    context "when post everyone for section" do
      before do
        Gradebook.manually_post_grades(@manual_assignment, "Everyone", @section2)
      end

      it "posts for section", priority: "1" do
        @section_two_students.each do |student|
          verify_grade_displayed_on_student_grade_page(student, "8", @manual_assignment, @course_with_manual_post)
        end
      end

      it "does not post for other section", priority: "1" do
        @section_one_students.each do |student|
          user_session(student)
          StudentGradesPage.visit_as_student(@course_with_manual_post)
          assignment_row = StudentGradesPage.assignment_row(@manual_assignment)
          expect(StudentGradesPage.hidden_eye_icon(scope: assignment_row)).to be_displayed
        end
      end

      it "hidden pill displayed in submission tray for other section", priority: "1" do
        Gradebook::Cells.open_tray(@section_one_students.first, @manual_assignment)
        expect(element_exists?(Gradebook::GradeDetailTray.hidden_pill_locator, true)).to be_truthy
      end

      it "Post tray shows unposted count", priority: "1" do
        Gradebook.click_post_grades(@manual_assignment.id)
        expect(PostGradesTray.unposted_count).to eq "2"
      end
    end

    context "when hide posted grades for everyone" do
      before :once do
        @manual_assignment.post_submissions(submission_ids: @submissions.pluck(:id))
      end

      before do
        Gradebook.click_hide_grades(@manual_assignment.id)
        HideGradesTray.hide_grades
      end

      it "header has hidden icon", priority: "1" do
        expect(Gradebook.assignment_hidden_eye_icon(@manual_assignment.id)).to be_displayed
      end

      it "student can see hidden icon", priority: "1" do
        user_session(@section_one_students.second)
        StudentGradesPage.visit_as_student(@course_with_manual_post)
        assignment_row = StudentGradesPage.assignment_row(@manual_assignment)
        expect(StudentGradesPage.hidden_eye_icon(scope: assignment_row)).to be_displayed

        user_session(@section_two_students.second)
        StudentGradesPage.visit_as_student(@course_with_manual_post)
        assignment_row = StudentGradesPage.assignment_row(@manual_assignment)
        expect(StudentGradesPage.hidden_eye_icon(scope: assignment_row)).to be_displayed
      end

      it "hidden pill displayed in submission tray", priority: "1" do
        Gradebook::Cells.open_tray(@section_two_students.first, @manual_assignment)
        expect(element_exists?(Gradebook::GradeDetailTray.hidden_pill_locator, true)).to be_truthy
      end
    end

    context "when hide posted grades for section" do
      before :once do
        @manual_assignment.post_submissions(submission_ids: @submissions.pluck(:id))
      end

      before do
        Gradebook.click_hide_grades(@manual_assignment.id)
        HideGradesTray.select_section(@section2.name)
        HideGradesTray.hide_grades
      end

      it "students in section have grades hidden", priority: "1" do
        @section_two_students.each do |student|
          user_session(student)
          StudentGradesPage.visit_as_student(@course_with_manual_post)
          assignment_row = StudentGradesPage.assignment_row(@manual_assignment)
          expect(StudentGradesPage.hidden_eye_icon(scope: assignment_row)).to be_displayed
        end
      end

      it "students in other section have grades posted", priority: "1" do
        @section_one_students.each do |student|
          verify_grade_displayed_on_student_grade_page(student, "8", @manual_assignment, @course_with_manual_post)
        end
      end
    end
  end

  context "when post for graded" do
    before :once do
      @graded_student = @students[0]
      @manual_assignment.grade_student(@graded_student, grade: 8, grader: @teacher1)
    end

    before do
      Gradebook.manually_post_grades(@manual_assignment, "Graded")
    end

    it "graded students see grades", priority: "1" do
      verify_grade_displayed_on_student_grade_page(@graded_student, "8", @manual_assignment, @course_with_manual_post)
    end

    it "does not post for ungraded", priority: "1" do
      user_session(@students[3])
      StudentGradesPage.visit_as_student(@course_with_manual_post)
      assignment_row = StudentGradesPage.assignment_row(@manual_assignment)
      expect(StudentGradesPage.hidden_eye_icon(scope: assignment_row)).to be_displayed
    end
  end

  context "when post graded for section" do
    before :once do
      @manual_assignment.grade_student(@section_two_students.first, grade: 8, grader: @teacher1)
      @section_one_students.each do |student|
        @manual_assignment.grade_student(student, grade: 8, grader: @teacher1)
      end
    end

    before do
      Gradebook.manually_post_grades(@manual_assignment, "Graded", @section2)
    end

    it "posts graded for section", priority: "1" do
      verify_grade_displayed_on_student_grade_page(@section_two_students.first, "8", @manual_assignment, @course_with_manual_post)
    end

    it "does not post ungraded for section", priority: "1" do
      user_session(@section_two_students.second)
      StudentGradesPage.visit_as_student(@course_with_manual_post)
      assignment_row = StudentGradesPage.assignment_row(@manual_assignment)
      expect(StudentGradesPage.hidden_eye_icon(scope: assignment_row)).to be_displayed
    end

    it "does not post graded for other section", priority: "1" do
      @section_one_students.each do |student|
        user_session(student)
        StudentGradesPage.visit_as_student(@course_with_manual_post)
        assignment_row = StudentGradesPage.assignment_row(@manual_assignment)
        expect(StudentGradesPage.hidden_eye_icon(scope: assignment_row)).to be_displayed
      end
    end
  end

  context "when Post Policy set to Automatically" do
    before do
      user_session(@teacher2)
      Gradebook.visit(@course_with_auto_post)
      Gradebook::Cells.edit_grade(@course_two_students.first, @auto_assignment, "9")
    end

    it "grades get posted immediately", priority: "1" do
      verify_grade_displayed_on_student_grade_page(@course_two_students.first, "9", @auto_assignment, @course_with_auto_post)
    end
  end

  context "assignment level post policy automatically" do
    before do
      Gradebook.click_grade_posting_policy(@manual_assignment.id)
      Gradebook::AssignmentPostingPolicy.post_policy_type_radio_button("Automatically").click
      Gradebook::AssignmentPostingPolicy.save_button.click

      Gradebook::Cells.edit_grade(@section_one_students.first, @manual_assignment, "9")
    end

    it "posts grade immediately", priority: "1" do
      verify_grade_displayed_on_student_grade_page(@section_one_students.first, "9", @manual_assignment, @course_with_manual_post)
    end
  end

  def verify_grade_displayed_on_student_grade_page(student, grade, assignment, course)
    user_session(student)
    StudentGradesPage.visit_as_student(course)
    expect(StudentGradesPage.fetch_assignment_score(assignment)).to eq grade
  end
end
