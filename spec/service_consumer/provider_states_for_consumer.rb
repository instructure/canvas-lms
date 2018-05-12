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
require_relative 'pact_setup'

Pact.provider_states_for 'Consumer' do
  provider_state 'a student in a course with an assignment' do
    set_up do
      course = SetupData.create_and_enroll_student_in_course
      SetupData.create_assignment(course)
    end

    tear_down do

    end
  end

  provider_state 'a student in a course' do
    set_up do
      SetupData.create_and_enroll_student_in_course
    end

    tear_down do

    end
  end
end
