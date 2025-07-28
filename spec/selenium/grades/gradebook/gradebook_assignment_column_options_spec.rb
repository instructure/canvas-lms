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

require_relative "../../helpers/gradebook_common"
require_relative "../../helpers/groups_common"
require_relative "../pages/gradebook_page"
require_relative "../pages/gradebook_cells_page"
require_relative "../pages/gradebook_grade_detail_tray_page"

# NOTE: We are aware that we're duplicating some unnecessary testcases, but this was the
# easiest way to review, and will be the easiest to remove after the feature flag is
# permanently removed. Testing both flag states is necessary during the transition phase.
shared_examples "Gradebook - Assignment Column" do |ff_enabled|
  include_context "in-process server selenium tests"
  include GradebookCommon
  include GroupsCommon

  before(:once) do
    # Set feature flag state for the test run - this affects how the gradebook data is fetched, not the data setup
    if ff_enabled
      Account.site_admin.enable_feature!(:performance_improvements_for_gradebook)
    else
      Account.site_admin.disable_feature!(:performance_improvements_for_gradebook)
    end

    course_with_teacher(active_all: true)

    # enroll three students
    3.times do |i|
      student = User.create!(name: "Student #{i + 1}")
      student.register!
      @course.enroll_student(student).update!(workflow_state: "active")
    end

    @assignment = @course.assignments.create!(
      title: "An Assignment",
      grading_type: "letter_grade",
      points_possible: 10,
      due_at: 1.day.from_now
    )

    @course.student_enrollments.collect(&:user).each do |student|
      @assignment.submit_homework(student, body: "a body")
      @assignment.grade_student(student, grade: "A", grader: @teacher)
    end
  end

  before { user_session(@teacher) }

  context "with Sorting" do
    it "sorts by Missing", priority: "1" do
      third_student = @course.students.find_by!(name: "Student 3")
      @assignment.submissions.find_by!(user: third_student).update!(late_policy_status: "missing")
      Gradebook.visit(@course)
      Gradebook.click_assignment_header_menu(@assignment.id)
      Gradebook.click_assignment_popover_sort_by("Missing")

      expect(Gradebook.fetch_student_names).to eq ["Student 3", "Student 1", "Student 2"]
    end

    it "sorts by Late" do
      third_student = @course.students.find_by!(name: "Student 3")
      submission = @assignment.submissions.find_by!(user: third_student)
      submission.update!(submitted_at: 2.days.from_now) # make late
      Gradebook.visit(@course)
      Gradebook.click_assignment_header_menu(@assignment.id)
      Gradebook.click_assignment_popover_sort_by("Late")

      expect(Gradebook.fetch_student_names).to eq ["Student 3", "Student 1", "Student 2"]
    end
  end

  context "with Enter Grades As Menu" do
    before do
      Gradebook.visit(@course)
    end

    it "can switch from letter grade to points", priority: "1" do
      # Initial grade is letter grade
      expect(Gradebook::Cells.get_grade(@course.students[2], @assignment)).to eq "A"

      # Change grade type to points
      Gradebook.click_assignment_popover_enter_grade_as(@assignment.id, "Points")
      wait_for_ajaximations

      expect(Gradebook::Cells.get_grade(@course.students[2], @assignment)).to eq "10"
    end

    it "can switch from letter grade to percentage and edit grade", priority: "1" do
      # Change grade type to percentage and re-grade
      Gradebook.click_assignment_popover_enter_grade_as(@assignment.id, "Percentage")
      Gradebook::Cells.edit_grade(@course.students[1], @assignment, 8)

      expect { Gradebook::Cells.get_grade(@course.students[1], @assignment) }.to become "8%"
    end

    it "active grading scheme displays a check", priority: "2" do
      # Initial grade is letter grade
      Gradebook.click_assignment_header_menu(@assignment.id)

      expect(Gradebook.enter_grade_as_popover_menu_item_checked?("Grading Scheme")).to eq "true"
    end

    it "grade detail tray has the new grading scheme", priority: "1" do
      # Initial grade is letter grade
      Gradebook.click_assignment_popover_enter_grade_as(@assignment.id, "Percentage")

      Gradebook::Cells.open_tray(@course.students[2], @assignment)
      expect(Gradebook::GradeDetailTray.grade_input.attribute("value")).to eq "100%"
    end

    it "tray accepts input per new grading scheme", priority: "2" do
      # Initial grade is letter grade and total of 10 points
      Gradebook.click_assignment_popover_enter_grade_as(@assignment.id, "Points")

      Gradebook::Cells.open_tray(@course.students[2], @assignment)
      Gradebook::GradeDetailTray.edit_grade(8.5)

      expect { Gradebook::Cells.get_grade(@course.students[2], @assignment) }.to become "8.5"
    end

    it "replace EX with Excused in Gradebook Cells", priority: "2" do
      # excuse the student by entering 'EX' in the cell
      Gradebook::Cells.edit_grade(@course.students[2], @assignment, "EX")

      expect { Gradebook::Cells.get_grade(@course.students[2], @assignment) }.to become "Excused"
    end
  end

  context "with anonymous assignment" do
    before do
      # enable anonymous flag at account level
      Account.default.enable_feature!(:anonymous_marking)

      # re-use the course and student setup from the describe block up-above
      # update assignment to be an anonymous assignment
      @assignment.update(title: "Anon Assignment", anonymous_grading: true)
      @assignment.submissions.update_all(posted_at: nil)

      # visit gradebook as teacher
      Gradebook.visit(@course)
    end

    it "assignment header cell contains ANONYMOUS label" do
      expect(Gradebook.select_assignment_header_secondary_label("Anon Assignment").text).to eq "ANONYMOUS"
    end

    it "speedgrader link on tray displays warning", priority: "1" do
      Gradebook::Cells.open_tray(@course.students.first, @assignment)
      Gradebook::GradeDetailTray.speedgrader_link.click

      expect(Gradebook.overlay_info_screen.text.split("\n")).to include(
        "Anonymous Mode On:",
        "Unable to access specific student. Go to assignment in SpeedGrader?"
      )
    end
  end
end

describe "Gradebook - Assignment Column" do
  it_behaves_like "Gradebook - Assignment Column", true
  it_behaves_like "Gradebook - Assignment Column", false
end
