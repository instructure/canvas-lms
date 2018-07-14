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

    provider_state 'a student with a to do item' do
      set_up do
        student = User.create!(name: 'student')
        Pseudonym.create!(user: student, unique_id: 'testuser@instructure.com')
        token = student.access_tokens.create!().full_token

        planner_note_model(user: student)
        provider_param :token, token
      end
    end
  end
end