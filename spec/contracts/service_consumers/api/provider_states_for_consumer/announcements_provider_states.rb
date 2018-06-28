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

    # Creates a course with a student enrolled and creates an announcement in the course.
    # Possible API endpoints: get, put and delete
    # Used by the spec: 'List Announcement'
    provider_state 'a student in a course with an announcement' do
      set_up do
        course_with_student(active_all: true, name: 'User_Student')
        Announcement.create!(context: @course, title: "Announcement1", message: "Announcement 1 detail")
      end
    end
  end
end