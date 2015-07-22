#
# Copyright (C) 2015 Instructure, Inc.
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
#

module Api::V1::SisAssignment
  include Api::V1::Json

  API_SIS_ASSIGNMENT_JSON_OPTS = {
    only: %i(id description created_at due_at points_possible integration_id integration_data).freeze,
    methods: %i(name).freeze
  }.freeze

  API_SIS_ASSIGNMENT_GROUP_JSON_OPTS = {
    only: %i(id name).freeze
  }.freeze

  API_SIS_ASSIGNMENT_COURSE_SECTION_JSON_OPTS = {
    only: %i(id name sis_source_id integration_id).freeze
  }.freeze

  API_SIS_ASSIGNMENT_COURSE_JSON_OPTS = {
    only: %i(id name sis_source_id integration_id).freeze
  }.freeze

  def sis_assignments_json(assignments)
    assignments.map { |a| sis_assignment_json(a) }
  end

  def sis_assignment_json(assignment)
    json = api_json(assignment, nil, nil, API_SIS_ASSIGNMENT_JSON_OPTS)
    json[:course_id] = assignment.context_id if assignment.context_type == 'Course'
    add_sis_assignment_group_json(assignment, json)
    add_sis_course_sections_json(assignment, json)
    json
  end

  def add_sis_assignment_group_json(assignment, json)
    return unless assignment.association(:assignment_group).loaded? && assignment.assignment_group
    json.merge!(assignment_group: sis_assignment_group_json(assignment.assignment_group))
  end

  def sis_assignment_group_json(assignment_group)
    api_json(assignment_group, nil, nil, API_SIS_ASSIGNMENT_GROUP_JSON_OPTS)
  end

  def add_sis_course_sections_json(assignment, json)
    return unless assignment.association(:context).loaded? && assignment.context.respond_to?(:course_sections)
    return unless assignment.context.association(:course_sections).loaded?
    json.merge!(sections: sis_assignment_course_sections_json(assignment.context.course_sections))
  end

  def sis_assignment_course_sections_json(course_sections)
    course_sections.map { |s| sis_assignment_course_section_json(s) }
  end

  def sis_assignment_course_section_json(course_section)
    json = api_json(course_section, nil, nil, API_SIS_ASSIGNMENT_COURSE_SECTION_JSON_OPTS)
    json[:sis_id] = json.delete(:sis_source_id)
    json[:origin_course] = sis_assignment_course_json(course_section.nonxlist_course || course_section.course)
    json[:xlist_course] = sis_assignment_course_json(course_section.course) if course_section.crosslisted?
    json
  end

  def sis_assignment_course_json(course)
    json = api_json(course, nil, nil, API_SIS_ASSIGNMENT_COURSE_JSON_OPTS)
    json[:sis_id] = json.delete(:sis_source_id)
    json
  end
end
