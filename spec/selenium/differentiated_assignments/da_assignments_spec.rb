# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require_relative "../helpers/assignments_common"
require_relative "../helpers/differentiated_assignments"

describe "interaction with differentiated assignments" do
  include_context "in-process server selenium tests"
  include DifferentiatedAssignments
  include AssignmentsCommon

  context "Student" do
    before do
      course_with_student_logged_in
      da_setup
      create_da_assignment
      @teacher = User.create!
      @course.enroll_teacher(@teacher)
    end

    context "Assignment Index" do
      it "hides assignments not visible" do
        create_section_override_for_assignment(@da_assignment, course_section: @section1)
        get "/courses/#{@course.id}/assignments"
        expect(f(".ig-empty-msg")).to include_text("No Assignment Groups found")
      end

      it "shows assignments with an override" do
        create_section_override_for_assignment(@da_assignment)
        get "/courses/#{@course.id}/assignments"
        expect(f("#assignment_group_upcoming")).to include_text(@da_assignment.title)
      end

      it "hides unassigned assignments with a graded submission" do
        @da_assignment.grade_student(@user, grade: 10, grader: @teacher)
        get "/courses/#{@course.id}/assignments"
        expect(f(".ig-empty-msg")).to include_text("No Assignment Groups found")
      end
    end

    context "Assignment Show page and Submission page" do
      it "redirects back to assignment index from inaccessible assignments" do
        create_section_override_for_assignment(@da_assignment, course_section: @section1)
        get "/courses/#{@course.id}/assignments/#{@da_assignment.id}"
        expect(f("#flash_message_holder")).to include_text("The assignment you requested is not available to your course section.")
        expect(driver.current_url).to match %r{/courses/\d+/assignments}
      end

      it "shows the assignment page with an override" do
        create_section_override_for_assignment(@da_assignment)
        get "/courses/#{@course.id}/assignments/#{@da_assignment.id}"
        expect(driver.current_url).to match %r{/courses/\d+/assignments/#{@da_assignment.id}}
      end

      it "does not show the assignment page for unassigned assignments with a graded submission" do
        @da_assignment.grade_student(@user, grade: 10, grader: @teacher)
        get "/courses/#{@course.id}/assignments/#{@da_assignment.id}"
        expect(f("#flash_message_holder")).to include_text("The assignment you requested is not available to your course section.")
        expect(driver.current_url).to match %r{/courses/\d+/assignments}
      end

      it "allows previous submissions to be accessed on an inaccessible assignment" do
        create_section_override_for_assignment(@da_assignment)
        @da_assignment.find_or_create_submission(@student)
        # destroy the override providing visibility to the current student
        AssignmentOverride.find(@da_assignment.assignment_overrides.first!.id).destroy
        get "/courses/#{@course.id}/assignments/#{@da_assignment.id}/submissions/#{@student.id}"
        # check the preview frame for the success banner and for your submission text
        in_frame("preview_frame") do
          expect(f("#flash_message_holder")).to include_text("This assignment will no longer count towards your grade.")
        end
      end
    end

    context "Student Grades Page" do
      it "shows assignments with an override" do
        create_section_override_for_assignment(@da_assignment)
        get "/courses/#{@course.id}/grades"
        expect(f("#assignments")).to include_text(@da_assignment.title)
      end

      it "does not show unassigned assignments with a graded submission" do
        @da_assignment.grade_student(@student, grade: 10, grader: @teacher)
        get "/courses/#{@course.id}/grades"
        expect(f("#assignments")).not_to include_text(@da_assignment.title)
      end

      it "does not show inaccessible assignments" do
        create_section_override_for_assignment(@da_assignment, course_section: @section1)
        get "/courses/#{@course.id}/grades"
        expect(f("#assignments")).not_to include_text(@da_assignment.title)
      end
    end
  end

  context "Observer with student" do
    before do
      observer_setup
      da_setup
      create_da_assignment
      @teacher = User.create!
      @course.enroll_teacher(@teacher)
    end

    context "Assignment Index" do
      it "hides inaccessible assignments" do
        create_section_override_for_assignment(@da_assignment, course_section: @section1)
        get "/courses/#{@course.id}/assignments"
        expect(f(".ig-empty-msg")).to include_text("No Assignment Groups found")
      end

      it "shows assignments with an override" do
        create_section_override_for_assignment(@da_assignment)
        get "/courses/#{@course.id}/assignments"
        expect(f("#assignment_group_upcoming")).to include_text(@da_assignment.title)
      end

      it "does not show unassigned assignments with a graded submission" do
        @da_assignment.grade_student(@user, grade: 10, grader: @teacher)
        get "/courses/#{@course.id}/assignments"
        expect(f(".ig-empty-msg")).to include_text("No Assignment Groups found")
      end
    end

    context "Assignment Show page and Submission page" do
      it "redirects back to assignment index from inaccessible assignments" do
        create_section_override_for_assignment(@da_assignment, course_section: @section1)
        get "/courses/#{@course.id}/assignments/#{@da_assignment.id}"
        expect(f("#flash_message_holder")).to include_text("The assignment you requested is not available to your course section.")
        expect(driver.current_url).to match %r{/courses/\d+/assignments}
      end

      it "shows the assignment page with an override" do
        create_section_override_for_assignment(@da_assignment)
        get "/courses/#{@course.id}/assignments/#{@da_assignment.id}"
        expect(driver.current_url).to match %r{/courses/\d+/assignments/#{@da_assignment.id}}
      end

      it "does not show the assignment page for an unassigned assignment with a graded submission" do
        @da_assignment.grade_student(@student, grade: 10, grader: @teacher)
        get "/courses/#{@course.id}/assignments/#{@da_assignment.id}"
        expect(f("#flash_message_holder")).to include_text("The assignment you requested is not available to your course section.")
        expect(driver.current_url).to match %r{/courses/\d+/assignments}
      end

      it "allows previous submissions to be accessed on an inaccessible assignment" do
        create_section_override_for_assignment(@da_assignment)
        @da_assignment.find_or_create_submission(@student)
        # destroy the override providing visibility to the current student
        AssignmentOverride.find(@da_assignment.assignment_overrides.first!.id).destroy
        get "/courses/#{@course.id}/assignments/#{@da_assignment.id}/submissions/#{@student.id}"
        # check the preview frame for the success banner and for your submission text
        in_frame("preview_frame") do
          expect(f("#flash_message_holder")).to include_text("This assignment will no longer count towards your grade.")
        end
      end
    end

    context "Student Grades Page" do
      it "shows assignments with an override" do
        create_section_override_for_assignment(@da_assignment)
        get "/courses/#{@course.id}/grades"
        expect(f("#assignments")).to include_text(@da_assignment.title)
      end

      it "does not show unassigned assignments with a graded submission" do
        @da_assignment.grade_student(@student, grade: 10, grader: @teacher)
        get "/courses/#{@course.id}/grades"
        expect(f("#assignments")).not_to include_text(@da_assignment.title)
      end

      it "does not show inaccessible assignments" do
        create_section_override_for_assignment(@da_assignment, course_section: @section1)
        get "/courses/#{@course.id}/grades"
        expect(f("#assignments")).not_to include_text(@da_assignment.title)
      end
    end
  end

  context "Teacher" do
    before do
      course_with_teacher_logged_in
      da_setup
      create_da_assignment
    end

    it "hides students from speedgrader if they are not assigned, and includes assigned students without visibility" do
      @s1, @s2, @s3 = create_users_in_course(@course, 3, return_type: :record, section_id: @default_section.id)
      @s4, @s5 = create_users_in_course(@course, 2, return_type: :record, section_id: @section1.id)
      create_section_override_for_assignment(@da_assignment, course_section: @section1)
      @course.enrollments.find_by(user: @s4).deactivate
      @teacher.set_preference(:gradebook_settings, @course.global_id, {
                                "show_inactive_enrollments" => "true",
                                "show_concluded_enrollments" => "false"
                              })

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@da_assignment.id}"
      f(".ui-selectmenu-icon").click
      [@s1, @s2, @s3].each do |student|
        expect(f("#students_selectmenu-menu")).not_to include_text(student.name.to_s)
      end
      [@s4, @s5].each do |student|
        expect(f("#students_selectmenu-menu")).to include_text(student.name.to_s)
      end
    end
  end
end
