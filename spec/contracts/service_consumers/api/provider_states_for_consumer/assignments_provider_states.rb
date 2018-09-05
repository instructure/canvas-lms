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

# require_relative '../../pact_config'
# require_relative '../pact_setup'

PactConfig::Consumers::ALL.each do |consumer|
  Pact.provider_states_for consumer do

    # Student ID: 5 || Student Name: Student1
    # Course ID: 1
    # Assignment ID: 1
    provider_state 'a student in a course with an assignment' do
      set_up do
        course = Pact::Canvas.base_state.course
        course.assignments.create({
                                   name: 'Assignment 1',
                                   due_at: Time.zone.now + 1.day,
                                   submission_types: 'online_text_entry'
                                 })
      end
    end

    provider_state 'a migrated quiz assignment' do
      set_up do
        course = Pact::Canvas.base_state.course
        assignment = assignment_model(context: course, title: 'Assignment1')
        assignment.submission_types = 'external_tool'
        assignment.external_tool_tag_attributes = {
          resource_link_id: '9b4ef1eea0eb4c3498983e09a6ef88f1'
        }
        assignment.save!
      end
    end

    provider_state 'a cloned quiz assignment' do
      set_up do
        course = Pact::Canvas.base_state.course
        assignment = assignment_model(context: course, title: 'Assignment1')
        assignment.submission_types = 'external_tool'
        assignment.external_tool_tag_attributes = {
          resource_link_id: '9b4ef1eea0eb4c3498983e09a6ef88f1'
        }
        assignment.save!
      end
    end

    provider_state 'an assignment with overrides' do
      set_up do
        course = Pact::Canvas.base_state.course
        student = Pact::Canvas.base_state.students.first
        assignment = course.assignments.create({
                                   name: 'Assignment Override',
                                   due_at: Time.zone.now + 1.day,
                                   submission_types: 'online_text_entry'
                                 })

        override = assignment.assignment_overrides.create!
        override.assignment_override_students.create!(:user => student)
      end
    end
  end
end
