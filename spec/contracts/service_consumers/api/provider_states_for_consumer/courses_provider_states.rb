#
# Copyright (C) 2018 - present Instructure, Inc.
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

PactConfig::Consumers::ALL.each do |consumer|
  Pact.provider_states_for consumer do

    # Creates a student in a course with a discussion.
    # Possible API endpoints: get, put and delete
    # Used by the spec: 'List Discussions'
    provider_state 'a student in a course with a discussion' do
      set_up do
        course_with_teacher(active_all: true, name: 'User_Teacher')
        @course.discussion_topics.create!(title: "title", message: nil, user: @teacher, discussion_type: 'threaded')
      end
    end

    # Creates a student in a course with a quiz.
    # Possible API endpoints: get, put and delete
    # Used by the spec: 'List Quizzes'
    provider_state 'a quiz in a course' do
      set_up do
          course_with_teacher(active_all: true, name: 'User_Teacher')
          @course.quizzes.create(title:'Test Quiz', description: 'Its a Quiz figure it out', due_at: 'Whenever')
      end
    end

    # Creates a student in a course.
    # Possible API endpoints: get and post.
    # Used by the spec: 'List Courses' 'List Students' 'List To Do Count for User'
    provider_state 'a student in a course' do
      set_up do
        course_with_student(active_all: true, name: 'User_Student')
        @teacher.name = 'User_Teacher'
        @teacher.save!
      end
    end

    # Creates a teacher in a course.
    # Possible API endpoints: get, post, delete and put
    # Used by the spec: 'Post Assignments' 'List Teachers' 'Delete a Course'
    provider_state 'a teacher in a course' do
      set_up do
        course_with_teacher(active_all: true, name: 'User_Teacher')
        Pseudonym.create!(user: @teacher, unique_id: 'testuser@instructure.com')
      end
    end

    # Creates a ta in a course.
    # Possible API endpoints: get, post, delete and put
    # Used by the spec: 'List TAs'
    provider_state 'a ta in a course' do
      set_up do
        course_with_ta(active_all: true, name: 'User_TA')
        Pseudonym.create!(user: @ta, unique_id: 'testuser@instructure.com')
      end
    end

    # Creates an observer in a course.
    # Possible API endpoints: get, post, delete and put
    # Used by the spec: 'List Observers'
    provider_state 'an observer in a course' do
      set_up do
        course_with_observer(active_all: true)
        teach = User.create!(name: 'User_Teacher')
        @course.enroll_user(teach, 'TeacherEnrollment')
      end
    end

    # Creates an admin in a course.
    # Possible API endpoints: get, post, put, delete.
    # Used by the spec: 'Create a Course' 'Update a Course'
    provider_state 'an admin in a course' do
      set_up do
        @admin = account_admin_user(name: 'User_Admin')
        @course = course_model
      end
    end

    # Creates a course with multiple sections.
    # Possible API endpoints: get, post, put, delete.
    # Used by the spec:
    provider_state 'multiple sections in a course' do
      set_up do
        course_with_teacher(active_all: true, name: 'User_Teacher')
        add_section("section1", @course)
        add_section("section2", @course)
        add_section("section3", @course)
        add_section("section4", @course)
      end
    end

    # Creates a course with a wiki page.
    # Possible API endpoints: get, post, put, delete.
    # Used by the spec: 'List Wiki Pages'
    provider_state 'a wiki page in a course' do
      set_up do
        course_with_teacher(active_all: true, name: 'User_Teacher')
        @course.wiki_pages.create!(title: "wiki_page")
      end
    end

    # Creates a student in a course with a submitted assignment.
    # Possible API endpoints: get, put, delete.
    # Used by the spec:
    provider_state 'a student in a course with a submitted assignment' do
      set_up do
        course_with_student_and_submitted_homework(name: 'User_Student')
        Pseudonym.create!(user: @teacher, unique_id: 'testuser@instructure.com')
      end
    end

    # Creates a student in a course with a missing assignment.
    # Possible API endpoints: get, put, delete.
    # Used by the spec:
    provider_state 'a student in a course with a missing assignment' do
      set_up do
        course_with_student(name: 'User_Student')
        Assignment.create!(context: @course, title: "Missing Assignment", due_at: Time.zone.now - 2)
      end
    end
  end
end