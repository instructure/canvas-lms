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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "courses/_to_do_list.html.erb" do
  include AssignmentsHelper

  context "as a student" do
    describe "with no assignments" do
      it "shows the new planner to do list anyway" do
        course_with_student(active_all: true)
        view_context
        render partial: "courses/to_do_list", locals: {contexts: nil}
        expect(response).to include '<div class="todo-list Sidebar__TodoListContainer">'
      end
    end
  end

  context "as a teacher" do
    describe "assignments to grade" do
      it "shows assignment data" do
        course_factory(active_all: true)
        due_date = 2.days.from_now
        assignment_model(course: @course,
                         due_at: due_date,
                         submission_types: "online_text_entry",
                         points_possible: 15,
                         title: "GradeMe")

        2.times do
          @course.enroll_student(user_factory).accept!
          @assignment.submit_homework(@user, {:submission_type => 'online_text_entry', :body => 'blah'})
        end

        @user = @teacher
        @user.course_nicknames[@course.id] = "My Awesome Course"
        @user.save!
        view_context
        # title, course nickname, points, due date, number of submissions to grade
        render partial: "courses/to_do_list", locals: {contexts: nil, show_legacy_todo_list: true}
        expect(response).to include "Grade GradeMe"
        expect(response).to include "15 points"
        expect(response).to include "My Awesome Course"
        expect(response).to include due_at(@assignment, @user)
        expect(response).to include "2"
        expect(response).to include "2 submissions need grading"
        expect(response).to include "Ignore GradeMe until new submission"
      end

      it "shows 999+ when there are more than 999 to grade" do
        course_with_student(active_all: true)
        due_date = 2.days.from_now
        assignment_model(course: @course,
                         due_at: due_date,
                         submission_types: "online_text_entry",
                         points_possible: 15,
                         title: "GradeMe")
        allow(Assignment).to receive(:need_grading_info).and_return(Assignment.where(id: @assignment.id))
        allow_any_instance_of(Assignments::NeedsGradingCountQuery).to receive(:manual_count).and_return(1000)
        @user = @teacher
        @user.course_nicknames[@course.id] = "My Awesome Course"
        @user.save!
        view_context
        # title, course nickname, points, due date, number of submissions to grade
        render partial: "courses/to_do_list", locals: {contexts: nil, show_legacy_todo_list: true}
        expect(response).to include "Grade GradeMe"
        expect(response).to include "15 points"
        expect(response).to include "My Awesome Course"
        expect(response).to include due_at(@assignment, @user)
        expect(response).to include "999+"
        expect(response).to include "More than 999 submissions need grading"
      end
    end

    describe "assignments to moderate" do
      it "shows assignment data" do
        course_with_student(active_all: true)
        due_date = 2.days.from_now
        assignment_model(
          course: @course,
          due_at: due_date,
          submission_types: "online_text_entry",
          points_possible: 15,
          title: "ModerateMe",
          moderated_grading: true,
          grader_count: 2,
          final_grader: @teacher
        )
        allow_any_instance_of(Assignments::NeedsGradingCountQuery).to receive(:manual_count).and_return(1)
        @submission = submission_model(assignment: @assignment, body: "my submission")
        @submission.find_or_create_provisional_grade!(@teacher, grade: 5)
        @user = @teacher
        @user.course_nicknames[@course.id] = "My Awesome Course"
        @user.save!
        view_context
        render partial: "courses/to_do_list", locals: {contexts: nil, show_legacy_todo_list: true}
        expect(response).to include "Moderate ModerateMe"
        expect(response).to include "Ignore ModerateMe until new mark"
      end

      it "does not show moderate link if user is not final grader" do
        course_with_student(active_all: true)
        second_teacher = @course.enroll_teacher(User.create!, enrollment_state: "active").user
        assignment_model(
          course: @course,
          submission_types: "online_text_entry",
          title: "ModerateMe",
          moderated_grading: true,
          final_grader: second_teacher,
          grader_count: 2
        )
        submission = submission_model(assignment: @assignment, body: "my submission")
        submission.find_or_create_provisional_grade!(@teacher, grade: 5)
        view_context
        render partial: "courses/to_do_list", locals: {contexts: nil, show_legacy_todo_list: true}
        expect(response).not_to include "Moderate ModerateMe"
      end
    end
  end
end
