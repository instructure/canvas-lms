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

    # Teacher ID: 3 || Name: Teacher1
    # Course ID: 1
    # Discussion ID: 1
    provider_state 'a teacher in a course with a discussion' do
      set_up do
        @course = Pact::Canvas.base_state.course
        @teacher = Pact::Canvas.base_state.teachers.first
        @course.discussion_topics.create!(title: "title", message: nil, user: @teacher, discussion_type: 'threaded')
      end
    end
  end
end