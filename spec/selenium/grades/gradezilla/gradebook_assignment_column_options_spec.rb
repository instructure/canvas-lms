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

require_relative '../../helpers/gradezilla_common'
require_relative '../../helpers/groups_common'
require_relative '../pages/gradezilla_page'
require_relative '../pages/gradezilla_cells_page'
require_relative '../pages/gradezilla_grade_detail_tray_page'

describe "Gradezilla - Assignment Column" do
  include_context "in-process server selenium tests"
  include GradezillaCommon
  include GroupsCommon

  before(:once) do
    course_with_teacher(active_all: true)

    # enroll three students
    3.times do |i|
      student = User.create!(name: "Student #{i+1}")
      student.register!
      @course.enroll_student(student).update!(workflow_state: 'active')
    end

    @assignment = @course.assignments.create!(
      title: "An Assignment",
      grading_type: 'letter_grade',
      points_possible: 10,
      due_at: 1.day.from_now
    )

    @course.student_enrollments.collect(&:user).each do |student|
      @assignment.submit_homework(student, body: 'a body')
      @assignment.grade_student(student, grade: 'A', grader: @teacher)
    end
  end

  before(:each) { user_session(@teacher) }

  context "with Sorting" do
    it "sorts by Missing", test_id: 3253336, priority: "1" do
      third_student = @course.students.find_by!(name: 'Student 3')
      @assignment.submissions.find_by!(user: third_student).update!(late_policy_status: "missing")
      Gradezilla.visit(@course)
      Gradezilla.click_assignment_header_menu(@assignment.id)
      Gradezilla.click_assignment_popover_sort_by('Missing')

      expect(Gradezilla.fetch_student_names).to eq ["Student 3", "Student 1", "Student 2"]
    end

    it "sorts by Late" do
      third_student = @course.students.find_by!(name: 'Student 3')
      submission = @assignment.submissions.find_by!(user: third_student)
      submission.update!(submitted_at: 2.days.from_now) # make late
      Gradezilla.visit(@course)
      Gradezilla.click_assignment_header_menu(@assignment.id)
      Gradezilla.click_assignment_popover_sort_by('Late')

      expect(Gradezilla.fetch_student_names).to eq ["Student 3", "Student 1", "Student 2"]
    end
  end

  context "with Enter Grades As Menu" do
    before(:each) do
      Gradezilla.visit(@course)
    end

    it "can switch from letter grade to points", priority: "1", test_id: 3415925 do
      # Initial grade is letter grade
      expect(Gradezilla::Cells.get_grade(@course.students[2], @assignment)).to eq 'A'

      # Change grade type to points
      Gradezilla.click_assignment_popover_enter_grade_as(@assignment.id, 'Points')
      wait_for_ajaximations

      expect(Gradezilla::Cells.get_grade(@course.students[2], @assignment)).to eq '10'
    end

    it "can switch from letter grade to percentage and edit grade", priority: "1", test_id: 3434871 do
      # Change grade type to percentage and re-grade
      Gradezilla.click_assignment_popover_enter_grade_as(@assignment.id, 'Percentage')
      Gradezilla::Cells.edit_grade(@course.students[1], @assignment, 8)

      expect { Gradezilla::Cells.get_grade(@course.students[1], @assignment) }.to become '8%'
    end

    it "active grading scheme displays a check", priority: "2", test_id: 3415924 do
      # Initial grade is letter grade
      Gradezilla.click_assignment_header_menu(@assignment.id)

      expect(Gradezilla.enter_grade_as_popover_menu_item_checked?('Grading Scheme')).to eq 'true'
    end

    it "grade detail tray has the new grading scheme", priority: "1", test_id: 3416270 do
      # Initial grade is letter grade
      Gradezilla.click_assignment_popover_enter_grade_as(@assignment.id, 'Percentage')

      Gradezilla::Cells.open_tray(@course.students[2], @assignment)
      expect(Gradezilla::GradeDetailTray.grade_input.attribute('value')).to eq '100%'
    end

    it "tray accepts input per new grading scheme", priority: "2", test_id: 3433716 do
      # Initial grade is letter grade and total of 10 points
      Gradezilla.click_assignment_popover_enter_grade_as(@assignment.id, 'Points')

      Gradezilla::Cells.open_tray(@course.students[2], @assignment)
      Gradezilla::GradeDetailTray.edit_grade(8.5)

      expect { Gradezilla::Cells.get_grade(@course.students[2], @assignment) }.to become '8.5'
    end

    it "replace EX with Excused in Gradebook Cells", priority: "2", test_id: 3424906 do
      # excuse the student by entering 'EX' in the cell
      Gradezilla::Cells.edit_grade(@course.students[2],@assignment, 'EX')

      expect { Gradezilla::Cells.get_grade(@course.students[2], @assignment) }.to become 'Excused'
    end
  end

  context "with anonymous assignment" do
    before(:each) do
      # enable anonymous flags at account level
      Account.default.enable_feature!(:anonymous_moderated_marking)
      Account.default.enable_feature!(:anonymous_marking)

      # re-use the course and student setup from the describe block up-above
      # update assignment to be an anonymous assignment
      @assignment.update_attributes(title: "Anon Assignment", anonymous_grading: true)

      # visit new gradebook as teacher
      Gradezilla.visit(@course)
    end

    it "assignment header cell contains ANONYMOUS label" do
      expect(Gradezilla.select_assignment_header_secondary_label('Anon Assignment').text).to eq 'ANONYMOUS'
    end

    it "speedgrader link on tray displays warning", priority: "1", test_id: 3481216 do
      Gradezilla::Cells.open_tray(@course.students.first, @assignment)
      Gradezilla::GradeDetailTray.speedgrader_link.click

      expect(Gradezilla.overlay_info_screen.text.split(/\n/)).to include(
        'Anonymous Mode On:',
        'Unable to access specific student. Go to assignment in SpeedGrader?'
      )
    end
  end
end
