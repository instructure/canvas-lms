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

    # Course ID: 1
    # Quizzes ID: 1
    provider_state 'a quiz in a course' do
      set_up do
        @course = Pact::Canvas.base_state.course
        @course.quizzes.create(title:'Test Quiz', description: 'Its a Quiz figure it out', due_at: 'Whenever')
      end
    end

    # Course ID: 1
    provider_state 'multiple sections in a course' do
      set_up do
        @course = Pact::Canvas.base_state.course
        add_section("section1", @course)
        add_section("section2", @course)
        add_section("section3", @course)
        add_section("section4", @course)
      end
    end

    # Student ID: 5 || Name: Student1
    # Course ID: 1
    # Quizzes ID: 1
    provider_state 'a student in a course with a submitted assignment' do
      set_up do
        @student = Pact::Canvas.base_state.students.first
        @course = Pact::Canvas.base_state.course
        @assignment = @course.assignments.create!({ title: "some assignment", submission_types: "online_url,online_upload" })
        @submission = @assignment.submit_homework(@student, { submission_type: "online_url", url: "http://www.google.com" })
      end
    end

    # Course ID: 1
    provider_state 'a student in a course with a missing assignment' do
      set_up do
        @course = Pact::Canvas.base_state.course
        Assignment.create!(context: @course, title: "Missing Assignment", due_at: Time.zone.now - 2)
      end
    end
  end
end