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
  end
end