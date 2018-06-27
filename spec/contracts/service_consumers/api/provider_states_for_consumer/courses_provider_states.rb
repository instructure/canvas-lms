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
    provider_state 'a student in a course with a discussion' do
      set_up do
        course_with_teacher(active_all: true)
        @course.discussion_topics.create!(title: "title", message: nil, user: @teacher, discussion_type: 'threaded')
        Pseudonym.create!(user: @teacher, unique_id: 'testuser@instructure.com')
        token = @teacher.access_tokens.create!().full_token

        provider_param :token, token
        provider_param :course_id, @course.id.to_s
      end
    end

    provider_state 'a student in a course with a quiz' do
      set_up do
          course_with_teacher(active_all: true)
          @course.quizzes.create(title:'Test Quiz', description: 'Its a Quiz figure it out', due_at: 'Whenever')
          Pseudonym.create!(user: @teacher, unique_id: 'testuser@instructure.com')
          token = @teacher.access_tokens.create!().full_token

          provider_param :token, token
          provider_param :course_id, @course.id.to_s
      end
    end

    provider_state 'a student in a course' do
      set_up do
        course_with_student(active_all: true)
        Pseudonym.create!(user: @student, unique_id: 'testuser@instructure.com')
        token = @student.access_tokens.create!().full_token

        provider_param :token, token
        provider_param :course_id, @course.id.to_s
      end
    end

    provider_state 'a teacher in a course' do
      set_up do
        course_with_teacher(active_all: true, name: 'Teacher')
        Pseudonym.create!(user: @teacher, unique_id: 'testuser@instructure.com')
        token = @teacher.access_tokens.create!().full_token

        provider_param :token, token
        provider_param :course_id, @course.id.to_s
      end
    end

    provider_state 'a ta in a course' do
      set_up do
        course_with_ta(active_all: true)
        Pseudonym.create!(user: @ta, unique_id: 'testuser@instructure.com')
        token = @ta.access_tokens.create!().full_token

        provider_param :token, token
        provider_param :course_id, @course.id.to_s
      end
    end

    provider_state 'an observer in a course' do
      set_up do
        course_with_observer(active_all: true)
        u = User.create!(name: 'teacher')
        @course.enroll_user(u, 'TeacherEnrollment')
        Pseudonym.create!(user: u, unique_id: 'testuser@instructure.com')
        token = u.access_tokens.create!().full_token

        provider_param :token, token
        provider_param :course_id, @course.id.to_s
      end
    end

    provider_state 'an admin in a course' do
      set_up do
        @admin = account_admin_user
        @course = course_model

        Pseudonym.create!(user:@admin, unique_id: 'testaccountuser@instructure.com')
        token = @admin.access_tokens.create!().full_token
        
        provider_param :token, token
        provider_param :account_id, @admin.id.to_s
        provider_param :course_id, @course.id.to_s
      end
    end

    provider_state 'multiple sections in a course' do
      set_up do
        course_with_teacher
        add_section("section1", @course)
        add_section("section2", @course)
        add_section("section3", @course)
        add_section("section4", @course)

        Pseudonym.create!(user: @teacher, unique_id: 'testuser@instructure.com')
        token = @teacher.access_tokens.create!().full_token
        provider_param :token, token
        provider_param :course_id, @course.id.to_s
      end
    end

    provider_state 'a wiki page in a course' do
      set_up do
        course_with_teacher
        wiki_page_model
        Pseudonym.create!(user: @teacher, unique_id: 'testuser@instructure.com')
        token = @teacher.access_tokens.create!().full_token

        provider_param :token, token
        provider_param :course_id, @course.id.to_s
      end
    end

    provider_state 'a student in a course with a submitted assignment' do
      set_up do
        course_with_student_and_submitted_homework
        Pseudonym.create!(user: @teacher, unique_id: 'testuser@instructure.com')
        token = @teacher.access_tokens.create!().full_token

        provider_param :course_id, @course.id.to_s
        provider_param :token, token

      end
    end

    provider_state 'a student in a course with a missing assignment' do
      set_up do
        course_with_student
        Assignment.create!(context: @course, title: "Missing Assignment", due_at: Time.zone.now - 2)
        Pseudonym.create!(user: @student, unique_id: 'testuser@instructure.com')
        token = @student.access_tokens.create!().full_token

        provider_param :course_id, @course.id.to_s
        provider_param :token, token
      end
    end
  end
end