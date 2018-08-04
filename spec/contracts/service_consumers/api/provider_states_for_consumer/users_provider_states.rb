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

    # Student ID: 5 || Name: Student1
    provider_state 'a student with a to do item' do
      set_up do
        student = Pact::Canvas.base_state.students.first
        planner_note_model(user: student)
      end
    end

    provider_state 'a teacher not in a course' do
      set_up do
        @teacher = user_factory(active_all: true, name: "Teacher2")
        @teacher.pseudonyms.create!(unique_id: "Teacher2@instructure.com", password: 'password', password_confirmation: 'password')
      end
    end
  end
end