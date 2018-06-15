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

require_relative '../pact_config'
require_relative 'pact_setup'

PactConfig::Consumers::ALL.each do |consumer|
  Pact.provider_states_for consumer do

    provider_state 'a student in a course with an assignment' do
      set_up do
        course_with_student(active_all: true)
        Assignment.create!(context: @course, title: "Assignment1")
        Pseudonym.create!(user: @student, unique_id: 'testuser@instructure.com')
        token = @student.access_tokens.create!().full_token

        provider_param :token, token
        provider_param :course_id, @course.id.to_s
        provider_param :user_id, @student.id.to_s
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

    provider_state 'a student in a course with an announcement' do
      set_up do
        course_with_student(active_all: true)
        Announcement.create!(context: @course, title: "Announcement1", message: "Announcement 1 detail")
        Pseudonym.create!(user: @student, unique_id: 'testuser@instructure.com')
        token = @student.access_tokens.create!().full_token

        provider_param :token, token
        provider_param :course_id, @course.id.to_s

      end
    end

    provider_state 'a user with a calendar event' do
      set_up do
        user_factory(name: 'Bob', active_user: true)
        Pseudonym.create!(user: @user, unique_id: 'testuser@instructure.com')
        token = @user.access_tokens.create!().full_token
        @event = @user.calendar_events.create!
      
        provider_param :token, token
        provider_param :event_id, @event.id.to_s
      end
    end

    provider_state 'a user with a robust calendar event' do
      set_up do
        course_with_teacher(:active_all => true)
        @ag = AppointmentGroup.create!(
          title: "Rohan's Special Day",
          location_name: "bollywood",
          location_address: "420 Baker Street",
          participants_per_appointment: 4,
          contexts: [@course],
          participant_visibility: "protected",
          new_appointments: [
            ["2012-01-01 12:59:59", "2012-01-01 13:59:59"],
            ["2012-01-01 13:59:59", "2012-01-01 14:59:59"]
          ]
        )
        course_with_student(course: @course, active_all: true)
        @ag.publish!
        @event = @ag.appointments.first
        @event.update!(all_day: true, all_day_date: '2015-09-22', description: "", location_name: "", location_address: "")
        @student1 = @student
        cat = @course.group_categories.create(name: "foo")
        g = cat.groups.create(:context => @course)
        g.users << @student
        @event.reserve_for(@student1, @student1)
        course_with_student(course: @course, active_all: true)
        @student2 = @student
        @event.reserve_for(@student2, @student2)
        
        Pseudonym.create!(user: @student, unique_id: 'testuser@instructure.com')
        token = @student.access_tokens.create!().full_token

        provider_param :token, token
        provider_param :event_id, @event.id.to_s
      end
    end

    provider_state 'a user with many calendar events' do
      set_up do
        user_factory(name: 'Bob', active_user: true)
        Pseudonym.create!(user: @user, unique_id: 'testuser@instructure.com')
        token = @user.access_tokens.create!().full_token

        @event0 = @user.calendar_events.create!
        @event1 = @user.calendar_events.create!
        @event2 = @user.calendar_events.create!
        @event3 = @user.calendar_events.create!

        provider_param :token, token
        provider_param :event_id0, @event0.id.to_s
        provider_param :event_id1, @event1.id.to_s
        provider_param :event_id2, @event2.id.to_s
        provider_param :event_id3, @event3.id.to_s
      end
    end

    provider_state 'a user with many notifications' do
      set_up do
        @user = user_factory(:active_all => true)
        @account = account_model
        @account_user = AccountUser.create(:account => @account, :user => @user)

        Pseudonym.create!(user:@user, unique_id: 'testaccountuser@instructure.com')
        token = @user.access_tokens.create!().full_token

        @notification1 = AccountNotification.create!(
          account: @account, subject: 'test subj1', message: 'test msg', start_at: Time.zone.now, end_at: 3.days.from_now
        )
        @notification2 = AccountNotification.create!(
          account: @account, subject: 'test subj2', message: 'test msg', start_at: Time.zone.now, end_at: 3.days.from_now
        )
        @notification3 = AccountNotification.create!(
          account: @account, subject: 'test subj3', message: 'test msg', start_at: Time.zone.now, end_at: 3.days.from_now
        )

        provider_param :token, token
        provider_param :account_id, @account.id.to_s
        provider_param :notification1_id, @notification1.id.to_s
        provider_param :notification2_id, @notification2.id.to_s
        provider_param :notification3_id, @notification3.id.to_s
      end
    end

    provider_state 'a user with many account reports' do
      set_up do
        @admin = account_admin_user

        Pseudonym.create!(user:@admin, unique_id: 'testadminaccount@instructure.com')
        token = @admin.access_tokens.create!().full_token

        @report = AccountReport.new
        @report.account = @admin.account
        @report.user = @admin
        @report.progress=rand(100)
        @report.start_at=Time.zone.now
        @report.end_at=(Time.zone.now + rand(60*60*4)).to_datetime
        @report.report_type = "student_assignment_outcome_map_csv"
        @report.parameters = HashWithIndifferentAccess['param' => 'test', 'error'=>'failed']
        folder = Folder.assert_path("test", @admin.account)
        @report.attachment = Attachment.create!(
          :folder => folder, :context => @admin.account, :filename => "test.txt", :uploaded_data => StringIO.new("test file")
        )
        @report.save!

        provider_param :token, token
        provider_param :account_id, @admin.account.id.to_s
        provider_param :report_type, @report.report_type.to_s
        provider_param :report_id, @report.id.to_s
      end
    end

        provider_state 'a student in a course with a discussion' do
      set_up do
        course_with_teacher(active_all: true)
        @course.discussion_topics.create!(:title => "title", :message => nil, :user => @teacher, :discussion_type => 'threaded')
        Pseudonym.create!(user: @teacher, unique_id: 'testuser@instructure.com')
        token = @teacher.access_tokens.create!().full_token

        provider_param :token, token
        provider_param :course_id, @course.id.to_s
      end
    end

    provider_state 'a student in a course with a quiz' do
      set_up do
          course_with_teacher(active_all: true)
          @course.quizzes.create(:title => 'Test Quiz', :description => 'Its a Quiz figure it out', :due_at=>'Whenever')
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
        course_with_teacher(active_all: true)
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


    provider_state 'a student' do
      set_up do
        student = User.create!(name: 'student')
        Pseudonym.create!(user: student, unique_id: 'testuser@instructure.com')
        token = student.access_tokens.create!().full_token
        provider_param :token, token
      end
    end

    provider_state 'a teacher' do
      set_up do
        teacher = User.create!(name: 'teacher')
        Pseudonym.create!(user: teacher, unique_id: 'testuser@instructure.com')
        token = teacher.access_tokens.create!().full_token
        provider_param :token, token

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

    provider_state 'a student with a to do item' do
      set_up do
        student = User.create!(name: 'student')
        Pseudonym.create!(user: student, unique_id: 'testuser@instructure.com')
        token = student.access_tokens.create!().full_token

        planner_note_model(user: student)
        provider_param :token, token
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
