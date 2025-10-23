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
require_relative "../pages/speedgrader_page"

describe "Individual View Gradebook" do
  include_context "in-process server selenium tests"
  include GradebookCommon

  before(:once) do
    # create a course with a teacher
    @teacher1 = course_with_teacher(course_name: "Course1", active_all: true).user

    # enroll a second teacher
    @teacher2 = course_with_teacher(course: @course, name: "Teacher2", active_all: true).user

    # enroll two students
    @student1 = course_with_student(course: @course, name: "Student1", active_all: true).user
    @student2 = course_with_student(course: @course, name: "Student2", active_all: true).user
  end

  context "with a moderated assignment" do
    before(:once) do
      # create moderated assignment
      @moderated_assignment = @course.assignments.create!(
        title: "Moderated Assignment1",
        grader_count: 2,
        final_grader_id: @teacher1.id,
        grading_type: "points",
        points_possible: 15,
        submission_types: "online_text_entry",
        moderated_grading: true
      )

      # give a grade as non-final grader
      @student1_submission = @moderated_assignment.grade_student(@student1, grade: 13, grader: @teacher2, provisional: true).first
    end

    before do
      # switch session to non-final-grader
      user_session(@teacher2)
    end

    it "prevents grading for the assignment before grades are posted" do
      EnhancedSRGB.visit(@course.id)
      EnhancedSRGB.select_student(@student1)
      EnhancedSRGB.select_assignment(@moderated_assignment)
      scroll_into_view('[data-testid="student_and_assignment_grade_input"]')

      expect(EnhancedSRGB.main_grade_input.attribute("disabled")).to eq "true"
      expect(EnhancedSRGB.excuse_checkbox.attribute("disabled")).to eq "true"
    end

    context "when grades are posted" do
      before(:once) do
        @moderated_assignment.update!(grades_published_at: Time.zone.now)
      end

      before do
        EnhancedSRGB.visit(@course.id)
      end

      it "allows grading for the assignment" do
        EnhancedSRGB.select_student(@student1)
        EnhancedSRGB.select_assignment(@moderated_assignment)

        EnhancedSRGB.enter_grade("15")
        expect(EnhancedSRGB.current_grade).to eq "15"
      end
    end
  end

  context "with an anonymous assignment" do
    before(:once) do
      # create a new anonymous assignment
      @anonymous_assignment = @course.assignments.create!(
        title: "Anonymous Assignment",
        submission_types: "online_text_entry",
        anonymous_grading: true,
        points_possible: 10
      )

      # create an unmuted anonymous assignment
      @unmuted_anonymous_assignment = @course.assignments.create!(
        title: "Unmuted Anon Assignment",
        submission_types: "online_text_entry",
        anonymous_grading: true,
        points_possible: 10
      )
      @unmuted_anonymous_assignment.unmute!
    end

    before do
      user_session(@teacher1)
      EnhancedSRGB.visit(@course.id)
    end

    it "excludes the muted assignment from the assignment list" do
      EnhancedSRGB.select_student(@student1)
      EnhancedSRGB.assignment_dropdown.click

      # muted anonymous assignment is not displayed
      expect(EnhancedSRGB.assignment_dropdown).not_to include_text "Anonymous Assignment"
      # unmuted anonymous assignment is displayed
      expect(EnhancedSRGB.assignment_dropdown).to include_text "Unmuted Anon Assignment"
    end

    it "speedgrader link opens in new tab" do
      EnhancedSRGB.select_assignment(@anonymous_assignment)
      scroll_into_view('[data-testid="assignment-speedgrader-link"]')

      speedgrader_link = EnhancedSRGB.speedgrader_link
      expect(speedgrader_link.attribute("target")).to eq("_blank")
      expect(speedgrader_link.attribute("href")).to include(
        "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@anonymous_assignment.id}"
      )
    end

    it "hides student names in speedgrader" do
      EnhancedSRGB.select_assignment(@anonymous_assignment)
      scroll_into_view('[data-testid="assignment-speedgrader-link"]')
      EnhancedSRGB.speedgrader_link.click

      driver.switch_to.window(driver.window_handles.last)

      Speedgrader.students_dropdown_button.click

      student_names = Speedgrader.students_select_menu_list.map(&:text)
      expect(student_names).to match_array ["Student 1", "Student 2"]
    end
  end
end
