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

require File.expand_path(File.dirname(__FILE__) + '/../helpers/assignments_common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/differentiated_assignments')

describe "interaction with differentiated assignments" do
  include_context "in-process server selenium tests"
  include DifferentiatedAssignments
  include AssignmentsCommon

  context "Student" do
    before :each do
      course_with_student_logged_in
      da_setup
      create_da_assignment
      @teacher = User.create!
      @course.enroll_teacher(@teacher)
    end

    context "Assignment Index" do
      it "should hide assignments not visible" do
        create_section_override_for_assignment(@da_assignment, course_section: @section1)
        get "/courses/#{@course.id}/assignments"
        expect(f(".ig-empty-msg")).to include_text("No Assignment Groups found")
      end
      it "should show assignments with an override" do
        create_section_override_for_assignment(@da_assignment)
        get "/courses/#{@course.id}/assignments"
        expect(f("#assignment_group_upcoming")).to include_text(@da_assignment.title)
      end
      it "should show assignments with a graded submission" do
        @da_assignment.grade_student(@user, grade: 10, grader: @teacher)
        get "/courses/#{@course.id}/assignments"
        expect(f("#assignment_group_undated")).to include_text(@da_assignment.title)
      end
    end

    context "Assignment Show page and Submission page" do
      it "should redirect back to assignment index from inaccessible assignments" do
        create_section_override_for_assignment(@da_assignment, course_section: @section1)
        get "/courses/#{@course.id}/assignments/#{@da_assignment.id}"
        expect(f("#flash_message_holder")).to include_text("The assignment you requested is not available to your course section.")
        expect(driver.current_url).to match %r{/courses/\d+/assignments}
      end
      it "should show the assignment page with an override" do
        create_section_override_for_assignment(@da_assignment)
        get "/courses/#{@course.id}/assignments/#{@da_assignment.id}"
        expect(driver.current_url).to match %r{/courses/\d+/assignments/#{@da_assignment.id}}
      end
      it "should show the assignment page with a graded submission" do
        @da_assignment.grade_student(@user, grade: 10, grader: @teacher)
        get "/courses/#{@course.id}/assignments/#{@da_assignment.id}"
        expect(driver.current_url).to match %r{/courses/\d+/assignments/#{@da_assignment.id}}
      end
      it "should allow previous submissions to be accessed on an inaccessible assignment" do
        create_section_override_for_assignment(@da_assignment)
        @da_assignment.find_or_create_submission(@student)
        # destroy the override providing visibility to the current student
        AssignmentOverride.find(@da_assignment.assignment_overrides.first!.id).destroy
        get "/courses/#{@course.id}/assignments/#{@da_assignment.id}/submissions/#{@student.id}"
        # check the preview frame for the success banner and for your submission text
        in_frame('preview_frame') do
          expect(f("#flash_message_holder")).to include_text("This assignment will no longer count towards your grade.")
        end
      end
    end

      context "Student Grades Page" do
        it "should show assignments with an override" do
          create_section_override_for_assignment(@da_assignment)
          get "/courses/#{@course.id}/grades"
          expect(f("#assignments")).to include_text(@da_assignment.title)
        end
        it "should show assignments with a graded submission" do
          @da_assignment.grade_student(@student, grade: 10, grader: @teacher)
          get "/courses/#{@course.id}/grades"
          expect(f("#assignments")).to include_text(@da_assignment.title)
        end
        it "should not show inaccessible assignments" do
          create_section_override_for_assignment(@da_assignment, course_section: @section1)
          get "/courses/#{@course.id}/grades"
          expect(f("#assignments")).not_to include_text(@da_assignment.title)
        end
      end
    end

  context "Observer with student" do
    before :each do
      observer_setup
      da_setup
      create_da_assignment
      @teacher = User.create!
      @course.enroll_teacher(@teacher)
    end

    context "Assignment Index" do
      it "should hide inaccessible assignments" do
        create_section_override_for_assignment(@da_assignment, course_section: @section1)
        get "/courses/#{@course.id}/assignments"
        expect(f(".ig-empty-msg")).to include_text("No Assignment Groups found")
      end
      it "should show assignments with an override" do
        create_section_override_for_assignment(@da_assignment)
        get "/courses/#{@course.id}/assignments"
        expect(f("#assignment_group_upcoming")).to include_text(@da_assignment.title)
      end
      it "should show assignments with a graded submission" do
        @da_assignment.grade_student(@user, grade: 10, grader: @teacher)
        get "/courses/#{@course.id}/assignments"
        expect(f("#assignment_group_undated")).to include_text(@da_assignment.title)
      end
    end

    context "Assignment Show page and Submission page" do
      it "should redirect back to assignment index from inaccessible assignments" do
        create_section_override_for_assignment(@da_assignment, course_section: @section1)
        get "/courses/#{@course.id}/assignments/#{@da_assignment.id}"
        expect(f("#flash_message_holder")).to include_text("The assignment you requested is not available to your course section.")
        expect(driver.current_url).to match %r{/courses/\d+/assignments}
      end
      it "should show the assignment page with an override" do
        create_section_override_for_assignment(@da_assignment)
        get "/courses/#{@course.id}/assignments/#{@da_assignment.id}"
        expect(driver.current_url).to match %r{/courses/\d+/assignments/#{@da_assignment.id}}
      end
      it "should show the assignment page with a graded submission" do
        @da_assignment.grade_student(@student, grade: 10, grader: @teacher)
        get "/courses/#{@course.id}/assignments/#{@da_assignment.id}"
        expect(driver.current_url).to match %r{/courses/\d+/assignments/#{@da_assignment.id}}
      end
      it "should allow previous submissions to be accessed on an inaccessible assignment" do
        create_section_override_for_assignment(@da_assignment)
        @da_assignment.find_or_create_submission(@student)
        # destroy the override providing visibility to the current student
        AssignmentOverride.find(@da_assignment.assignment_overrides.first!.id).destroy
        get "/courses/#{@course.id}/assignments/#{@da_assignment.id}/submissions/#{@student.id}"
        # check the preview frame for the success banner and for your submission text
        in_frame('preview_frame') do
          expect(f("#flash_message_holder")).to include_text("This assignment will no longer count towards your grade.")
        end
      end
    end

    context "Student Grades Page" do
      it "should show assignments with an override" do
        create_section_override_for_assignment(@da_assignment)
        get "/courses/#{@course.id}/grades"
        expect(f("#assignments")).to include_text(@da_assignment.title)
      end
      it "should show assignments with a graded submission" do
        @da_assignment.grade_student(@student, grade: 10, grader: @teacher)
        get "/courses/#{@course.id}/grades"
        expect(f("#assignments")).to include_text(@da_assignment.title)
      end
      it "should not show inaccessible assignments" do
        create_section_override_for_assignment(@da_assignment, course_section: @section1)
        get "/courses/#{@course.id}/grades"
        expect(f("#assignments")).not_to include_text(@da_assignment.title)
      end
    end
  end

  context "Teacher" do
    before :each do
      course_with_teacher_logged_in
      da_setup
      create_da_assignment
    end
    it "should hide students from speedgrader if they don't have Differentiated assignment visibility or a graded submission" do
      @s1, @s2, @s3 = create_users_in_course(@course, 3, return_type: :record, section_id: @default_section.id)
      @s4, @s5 = create_users_in_course(@course, 2, return_type: :record, section_id: @section1.id)
      create_section_override_for_assignment(@da_assignment, course_section: @section1)
      @da_assignment.grade_student(@s3, grade: 10, grader: @teacher)

      # evaluate for our data
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@da_assignment.id}"
      f(".ui-selectmenu-icon").click
      [@s1, @s2].each do |student|
        expect(f("#students_selectmenu-menu")).not_to include_text("#{student.name}")
      end
      [@s3, @s4, @s5].each do |student|
        expect(f("#students_selectmenu-menu")).to include_text("#{student.name}")
      end
    end
  end
end
