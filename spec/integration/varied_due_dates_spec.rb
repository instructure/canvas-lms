#
# Copyright (C) 2012 Instructure, Inc.
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
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "varied due dates" do
  include TextHelper

  let(:multiple_due_dates) { "Multiple Due Dates" }

  def assert_coming_up_due_date(response, expected)
    doc = Nokogiri::XML(response.body)
    doc.at_css("#right-side .coming_up .event a .tooltip_text").text.should include(
      expected.is_a?(String) ? expected : datetime_string(expected)
    )
  end

  def assert_todo_due_date(response, expected)
    doc = Nokogiri::XML(response.body)
    doc.at_css("#right-side .to-do-list").text.should include(
      expected.is_a?(String) ? expected : datetime_string(expected)
    )
  end

  def assert_recent_feedback_due_date(response, expected)
    doc = Nokogiri::XML(response.body)
    doc.at_css("#right-side .recent_feedback .event a .tooltip_text").text.should include(
      expected.is_a?(String) ? expected : datetime_string(expected)
    )
  end


  before do
    # Create a course with a student
    course_with_student(:active_all => true)
    @student1 = user_with_pseudonym :user => @student

    # Enroll another student
    @s2enrollment = student_in_course(:course => @course, :active_all => true)
    @student2 = user_with_pseudonym :user => @user

    # Create another section
    @section = @course.course_sections.create!

    # Add the second student to the new section
    @s2enrollment.course_section = @section; @s2enrollment.save!

    # Let's enroll another student, this one in both sections
    @s3enrollment1 = student_in_course(:course => @course, :active_all => true)
    @student3 = user_with_pseudonym :user => @user

    @s3enrollment2 = @s3enrollment1.clone
    @s3enrollment2.course_section = @section ; @s3enrollment2.save!

    # Create an assignment
    @course_due_date = 3.days.from_now
    @section_due_date = 5.days.from_now


    teacher = course_with_teacher(:course => @course, :active_all => true)
    @teacher = user_with_pseudonym :user => @user

    create_coming_up_assignment
  end

  def create_recent_feedback(student)
    submission = @assignment.find_or_create_submission(student)
    @assignment.update_submission(student, {
      :comment => 'you should turn this in ...',
      :commenter => @teacher
    })
  end

  def create_teacher_todo_assignment
    @teacher_todo_assignment = @course.assignments.create!(
      :title => "Teacher Todo",
      :due_at => @course_due_date,
      :submission_types => "online_text_entry"
    )
    create_override_for(@teacher_todo_assignment, @section_due_date)
    @submission = @teacher_todo_assignment.submit_homework(@student1, {
      :submission_type => "online_text_entry",
      :body => "canvas ate my homework"
    })
    @submission.save!
  end

  def create_student_todo_assignment
    @student_todo_course_due_at = 1.day.from_now
    @student_todo_section_due_at = 2.days.from_now
    @student_todo_assignment = @course.assignments.create!(
      :title => "Student Todo",
      :due_at => @student_todo_course_due_at,
      :submission_types => 'online_text_entry'
    )
    @student_todo_override = create_override_for(@student_todo_assignment, @student_todo_section_due_at)
  end

  def create_coming_up_assignment
    @assignment = @course.assignments.create!(
      :title => "Test Assignment",
      :due_at => @course_due_date
    )
    @coming_up_override = create_override_for(@assignment, @section_due_date)
  end

  def create_override_for(assignment, due_at)
    override = AssignmentOverride.new
    override.assignment = assignment
    override.set = @section
    override.due_at = due_at
    override.due_at_overridden = true
    override.save!
    override
  end

  context "on the dashboard" do
    def wrap_partial(response)
      response.body = "<html id='right-side'>#{response.body}</html>"
      response
    end

    context "as a student" do
      context "in the base section" do
        it "shows the course due date in 'todo'" do
          create_student_todo_assignment
          login_as(@student1.pseudonym.login, 'asdfasdf')
          get '/dashboard-sidebar'
          assert_todo_due_date wrap_partial(response), @student_todo_course_due_at
        end

        it "shows the course due date in 'coming up'" do
          login_as(@student1.pseudonym.login, 'asdfasdf')
          get '/dashboard-sidebar'
          assert_coming_up_due_date wrap_partial(response), @course_due_date
        end

        it "shows the course due date in 'recent feedback'" do
          create_recent_feedback @student1
          login_as(@student1.pseudonym.login, 'asdfasdf')
          get '/dashboard-sidebar'
          assert_recent_feedback_due_date wrap_partial(response), @course_due_date
        end
      end

      context "in the overridden section" do
        it "shows the section due date in 'todo'" do
          create_student_todo_assignment
          login_as(@student2.pseudonym.login, 'asdfasdf')
          get '/dashboard-sidebar'
          assert_todo_due_date wrap_partial(response), @student_todo_section_due_at
        end

        it "shows the section due date in 'coming up" do
          login_as(@student2.pseudonym.login, 'asdfasdf')
          get '/dashboard-sidebar'
          assert_coming_up_due_date wrap_partial(response), @section_due_date
        end

        it "shows the section due date in 'recent feedback'" do
          create_recent_feedback @student2
          login_as(@student2.pseudonym.login, 'asdfasdf')
          get '/dashboard-sidebar'
          assert_recent_feedback_due_date wrap_partial(response), @section_due_date
        end
      end
    end

    context "as the teacher" do
      it "shows multiple due dates in 'coming up'" do
        login_as(@teacher.pseudonym.login, 'asdfasdf')
        get '/dashboard-sidebar'
        assert_coming_up_due_date wrap_partial(response), multiple_due_dates
      end

      it "shows multiple due dates in 'todo'" do
        create_teacher_todo_assignment
        login_as(@teacher.pseudonym.login, 'asdfasdf')
        get '/dashboard-sidebar'
        assert_todo_due_date wrap_partial(response), multiple_due_dates
      end
    end
  end

  context "on the assignments page" do

    def assert_due_date(response, expected)
      doc = Nokogiri::XML(response.body)

      [ "#assignment_#{@assignment.id} .date_text",
        "#right-side .event a em"
      ].each do |selector|
        doc.at_css(selector).text.should include(
          expected.is_a?(String) ? expected : date_string(expected)
        )
      end
      assert_coming_up_due_date(response, expected)
    end

    def formatted_date(string)
      TextHelper.date_string(string)
    end

    context "an assignment that has a course due date and a section due date" do

      context "as a student" do

        context "in the base section" do
          it "shows the course due date" do
            user_session(@student1)
            get "/assignments"

            assert_due_date response, @course_due_date
            response.body.should_not include formatted_date(@section_due_date)
            response.body.should_not include multiple_due_dates
          end
        end

        context "in the overridden section" do
          it "shows the section due date" do
            user_session(@student2)
            get "/assignments"

            assert_due_date response, @section_due_date
            response.body.should_not include formatted_date(@course_due_date)
            response.body.should_not include multiple_due_dates
          end
        end

        context "in both the base section and the overridden section (it could happen)" do
          it "shows the more lenient due date (section due date in this case)" do
            user_session(@student2)
            get "/assignments"

            assert_due_date response, @section_due_date
            response.body.should_not include formatted_date(@course_due_date)
            response.body.should_not include multiple_due_dates
          end
        end
      end

      context "as the teacher" do
        it "shows multiple due dates" do
          course_with_teacher_logged_in(:course => @course, :active_all => true)
          get "/assignments"

          assert_due_date response, multiple_due_dates
          response.body.should_not include formatted_date(@course_due_date)
          response.body.should_not include formatted_date(@section_due_date)
        end
      end

      context "as a TA" do
        it "shows multiple due dates" do
          course_with_ta(:course => @course, :active_all => true)
          user_session(@ta)

          get "/assignments"

          assert_due_date response, multiple_due_dates
          response.body.should_not include formatted_date(@course_due_date)
          response.body.should_not include formatted_date(@section_due_date)          
        end
      end

      context "as an observer" do
        before do
          course_with_observer(:course => @course, :active_all => true)
          user_session(@observer)
        end

        context "assigned to students" do
          context "assigned to a student in the base section" do
            it "shows the course due date" do
              @enrollment.update_attribute(:associated_user_id, @student1.id)
              get "/assignments"

              assert_due_date response, @course_due_date
              response.body.should_not include formatted_date(@section_due_date)
              response.body.should_not include multiple_due_dates
            end
          end

          context "assigned to a student in the overridden section" do
            it "shows the section due date" do
              @enrollment.update_attribute(:associated_user_id, @student2.id)
              get "/assignments"

              assert_due_date response, @section_due_date
              response.body.should_not include formatted_date(@course_due_date)
              response.body.should_not include multiple_due_dates              
            end
          end

          context "assigned to a student in multiple sections" do
            it "shows the more lenient due date (section in this case)" do
              @enrollment.update_attribute(:associated_user_id, @student3.id)
              get "/assignments"

              assert_due_date response, @section_due_date
              response.body.should_not include formatted_date(@course_due_date)
              response.body.should_not include multiple_due_dates              
            end
          end
        end

        context "not assigned to any students" do
          context "enrolled in the base section" do
            it "shows the course due date" do
              get "/assignments"

              assert_due_date response, @course_due_date
              response.body.should_not include formatted_date(@section_due_date)
              response.body.should_not include multiple_due_dates
            end
          end

          context "enrolled in the overridden section" do
            it "shows the section due date" do
              @enrollment.course_section = @section ; @enrollment.save!

              get "/assignments"

              assert_due_date response, @section_due_date
              response.body.should_not include formatted_date(@course_due_date)
              response.body.should_not include multiple_due_dates
            end
          end
        end
      end

      context "as a course designer" do
        it "shows multiple due dates" do
          course_with_designer(:course => @course, :active_all => true)
          user_session(@designer)

          get "/assignments"

          assert_due_date response, multiple_due_dates
          response.body.should_not include formatted_date(@course_due_date)
          response.body.should_not include formatted_date(@section_due_date)          
        end
      end

      describe "as an account admin, accessing the course assignments page" do
        before do
          account_admin_user
          user_session(@admin)
        end

        context "with overrides" do
          it "shows multiple due dates" do
            get course_assignments_path(@course)
            response.body.should include multiple_due_dates
          end
        end

        context "with no overrides" do
          it "shows the course due date" do
            AssignmentOverride.delete_all
            get course_assignments_path(@course)
            response.body.should include formatted_date(@course_due_date)
          end
        end
      end

      describe "with caching" do
        it "shows the right due dates" do
          enable_cache do
            { @student1 => @course_due_date, @student2 => @section_due_date }.each do |student, due_date|
              user_session(student)
              get "/assignments"
              assert_due_date response, due_date
            end
          end
        end
      end
    end
  end
end
