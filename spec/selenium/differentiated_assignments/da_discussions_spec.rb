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

describe "interaction with differentiated discussions" do
  include_context "in-process server selenium tests"
  include DifferentiatedAssignments
  include AssignmentsCommon

  context "Student" do
    before :each do
      course_with_student_logged_in
      da_setup
      create_da_discussion
    end

    context "Discussion and Assignment Index" do
      it "should hide inaccessible discussions" do
        create_section_override_for_assignment(@da_discussion.assignment, course_section: @section1)
        get "/courses/#{@course.id}/assignments"
        expect(f(".ig-empty-msg")).to include_text("No Assignment Groups found")
        get "/courses/#{@course.id}/discussion_topics/"
        expect(f("#open-discussions")).to include_text("There are no discussions to show in this section.")
      end
      it "should show discussions with an override" do
        create_section_override_for_assignment(@da_discussion.assignment) #on default section
        get "/courses/#{@course.id}/assignments"
        expect(f("#assignment_group_upcoming")).to include_text(@da_discussion.title)
        get "/courses/#{@course.id}/discussion_topics/"
        expect(f("#open-discussions")).to include_text(@da_discussion.title)
      end
      it "should show discussions with a graded submission" do
        @teacher = User.create!
        @course.enroll_teacher(@teacher)
        @da_discussion.assignment.grade_student(@student, grade: 10, grader: @teacher)
        get "/courses/#{@course.id}/assignments"
        expect(f("#assignment_group_upcoming")).to include_text(@da_discussion.title)
        get "/courses/#{@course.id}/discussion_topics/"
        expect(f("#open-discussions")).to include_text(@da_discussion.title)
      end
    end

    context "Discussion Show page" do
      it "should redirect back to discussion index from inaccessible discussions" do
        create_section_override_for_assignment(@da_discussion.assignment) #on default section
        @da_discussion.reply_from(:user => @user, :text => 'hello')
        @da_discussion.assignment.assignment_overrides.each(&:destroy_permanently!)
        create_section_override_for_assignment(@da_discussion.assignment, course_section: @section1)
        get "/courses/#{@course.id}/discussion_topics/#{@da_discussion.id}"
        expect(f("#flash_message_holder")).to include_text("You do not have access to the requested discussion.")
        expect(driver.current_url).to match %r{/courses/\d+/discussion_topics}
      end
      it "should show the discussion page with an override" do
        create_section_override_for_assignment(@da_discussion.assignment) #on default section
        get "/courses/#{@course.id}/discussion_topics/#{@da_discussion.id}"
        expect(driver.current_url).to match %r{/courses/\d+/discussion_topics/#{@da_discussion.id}}
      end
      it "should show the discussion page with a graded submission" do
        @teacher = User.create!
        @course.enroll_teacher(@teacher)
        @da_discussion.assignment.grade_student(@user, grade: 10, grader: @teacher)
        get "/courses/#{@course.id}/discussion_topics/#{@da_discussion.id}"
        expect(driver.current_url).to match %r{/courses/\d+/discussion_topics/#{@da_discussion.id}}
      end
    end

    context "Student Grades Page" do
      it "should show discussions with an override" do
        create_section_override_for_assignment(@da_discussion.assignment) #on default section
        get "/courses/#{@course.id}/grades"
        expect(f("#assignments")).to include_text(@da_discussion.title)
      end
      it "should show discussions with a graded submission" do
        @teacher = User.create!
        @course.enroll_teacher(@teacher)
        @da_discussion.assignment.grade_student(@student, grade: 10, grader: @teacher)
        get "/courses/#{@course.id}/grades"
        expect(f("#assignments")).to include_text(@da_discussion.title)
      end
      it "should not show inaccessible discussions" do
        create_section_override_for_assignment(@da_discussion.assignment, course_section: @section1)
        get "/courses/#{@course.id}/grades"
        expect(f("#assignments")).not_to include_text(@da_discussion.title)
      end
    end
  end

  context "Observer with student" do
    before :each do
      observer_setup
      da_setup
      create_da_discussion
    end

    context "Discussion and Assignment Index" do
      it "should not show inaccessible discussions" do
        create_section_override_for_assignment(@da_discussion.assignment, course_section: @section1)
        get "/courses/#{@course.id}/assignments"
        expect(f(".ig-empty-msg")).to include_text("No Assignment Groups found")
        get "/courses/#{@course.id}/discussion_topics/"
        expect(f("#open-discussions")).to include_text("There are no discussions to show in this section.")
      end
      it "should show discussions with an override" do
        create_section_override_for_assignment(@da_discussion.assignment) #on default section
        get "/courses/#{@course.id}/assignments"
        expect(f("#assignment_group_upcoming")).to include_text(@da_discussion.title)
        get "/courses/#{@course.id}/discussion_topics/"
        expect(f("#open-discussions")).to include_text(@da_discussion.title)
      end
      it "should show discussions with a graded submission" do
        @teacher = User.create!
        @course.enroll_teacher(@teacher)
        @da_discussion.assignment.grade_student(@student, grade: 10, grader: @teacher)
        get "/courses/#{@course.id}/assignments"
        expect(f("#assignment_group_upcoming")).to include_text(@da_discussion.title)
        get "/courses/#{@course.id}/discussion_topics/"
        expect(f("#open-discussions")).to include_text(@da_discussion.title)
      end
    end

    context "Discussion Show page" do
      it "should redirect back to discussion index from inaccessible discussions" do
        create_section_override_for_assignment(@da_discussion.assignment) #on default section
        @da_discussion.reply_from(:user => @user, :text => 'hello')
        @da_discussion.assignment.assignment_overrides.each(&:destroy_permanently!)
        create_section_override_for_assignment(@da_discussion.assignment, course_section: @section1)
        get "/courses/#{@course.id}/discussion_topics/#{@da_discussion.id}"
        expect(f("#flash_message_holder")).to include_text("You do not have access to the requested discussion.")
        expect(driver.current_url).to match %r{/courses/\d+/discussion_topics}
      end
      it "should show the discussion page with an override" do
        create_section_override_for_assignment(@da_discussion.assignment) #on default section
        get "/courses/#{@course.id}/discussion_topics/#{@da_discussion.id}"
        expect(driver.current_url).to match %r{/courses/\d+/discussion_topics/#{@da_discussion.id}}
      end
      it "should show the discussion page with a graded submission" do
        @teacher = User.create!
        @course.enroll_teacher(@teacher)
        @da_discussion.assignment.grade_student(@user, grade: 10, grader: @teacher)
        get "/courses/#{@course.id}/discussion_topics/#{@da_discussion.id}"
        expect(driver.current_url).to match %r{/courses/\d+/discussion_topics/#{@da_discussion.id}}
      end
    end

    context "Student Grades Page" do
      it "should show discussions with an override" do
        create_section_override_for_assignment(@da_discussion.assignment) #on default section
        get "/courses/#{@course.id}/grades"
        expect(f("#assignments")).to include_text(@da_discussion.title)
      end
      it "should show discussions with a graded submission" do
        @teacher = User.create!
        @course.enroll_teacher(@teacher)
        @da_discussion.assignment.grade_student(@student, grade: 10, grader: @teacher)
        get "/courses/#{@course.id}/grades"
        expect(f("#assignments")).to include_text(@da_discussion.title)
      end
      it "should not show inaccessible discussions" do
        create_section_override_for_assignment(@da_discussion.assignment, course_section: @section1)
        get "/courses/#{@course.id}/grades"
        expect(f("#assignments")).not_to include_text(@da_discussion.title)
      end
    end
  end
end
