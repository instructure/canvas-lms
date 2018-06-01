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

require_relative '../../../../pact/pact_config'
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

    provider_state 'a user with many calendar events' do
      set_up do
        user_factory(name: 'Bob', active_user: true)
        Pseudonym.create!(user: @user, unique_id: 'testuser@instructure.com')
        token = @user.access_tokens.create!().full_token
      end
    end
  end
end
