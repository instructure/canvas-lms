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

    # User ID: 2 || Name: Admin1
    # Event ID: 1
    provider_state 'a user with a calendar event' do
      set_up do
        @user = Pact::Canvas.base_state.account_admins.first
        @event = @user.calendar_events.create!
      end
    end

    # Student ID: 2 || Name: Student1
    # Teacher ID: 4 || Name: Teacher1
    # Event ID: 1
    provider_state 'a user with a robust calendar event' do
      set_up do
        @course = Pact::Canvas.base_state.course
        @student = Pact::Canvas.base_state.students.first
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
      end
    end

    # User ID: 2 || Name: Admin1
    # Event ID: 1, 2, 3, 4.
    provider_state 'a user with many calendar events' do
      set_up do
        @user = Pact::Canvas.base_state.account_admins.first
        @event0 = @user.calendar_events.create!
        @event1 = @user.calendar_events.create!
        @event2 = @user.calendar_events.create!
        @event3 = @user.calendar_events.create!
      end
    end
  end
end