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
    only: %i(id created_at due_at unlock_at lock_at points_possible integration_id integration_data include_in_final_grade).freeze,
    methods: %i(name submission_types_array).freeze
  }.freeze

  API_SIS_ASSIGNMENT_GROUP_JSON_OPTS = {
    only: %i(id name sis_source_id integration_data group_weight).freeze
  }.freeze

  API_SIS_ASSIGNMENT_COURSE_SECTION_JSON_OPTS = {
    only: %i(id name sis_source_id integration_id).freeze
  }.freeze

  API_SIS_ASSIGNMENT_COURSE_JSON_OPTS = {
    only: %i(id name sis_source_id integration_id).freeze
  }.freeze

  API_SIS_ASSIGNMENT_OVERRIDES_JSON_OPTS = {
    only: %i(title due_at unlock_at lock_at).freeze
  }.freeze

  def sis_assignments_json(assignments)
    assignments.map { |a| sis_assignment_json(a) }
  end

  def sis_assignment_json(assignment)
    json = api_json(assignment, nil, nil, API_SIS_ASSIGNMENT_JSON_OPTS)
    json[:course_id] = assignment.context_id if assignment.context_type == 'Course'
    json[:submission_types] = json.delete(:submission_types_array)
    json[:include_in_final_grade] = include_in_final_grade(assignment)
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
    return unless assignment.association(:context).loaded?
    course_sections = active_course_sections_for(assignment.context)
    return unless course_sections
    json.merge!(sections: sis_assignment_course_sections_json(course_sections, assignment))
  end

  def sis_assignment_course_sections_json(course_sections, assignment)
    if assignment.only_visible_to_overrides
      section_ids = active_assignment_overrides_for(assignment).map { |o| o.set_id if o.set_type == 'CourseSection' }
      section_ids = Set.new(section_ids.compact)
      course_sections = course_sections.select { |section| section_ids.include?(section.id) }
    end

    course_sections.map { |s| sis_assignment_course_section_json(s, assignment) }
  end

  def sis_assignment_course_section_json(course_section, assignment)
    json = api_json(course_section, nil, nil, API_SIS_ASSIGNMENT_COURSE_SECTION_JSON_OPTS)
    json[:sis_id] = json.delete(:sis_source_id)
    json[:origin_course] = sis_assignment_course_json(course_section.nonxlist_course || course_section.course)
    json[:xlist_course] = sis_assignment_course_json(course_section.course) if course_section.crosslisted?
    add_sis_assignment_override_json(json, assignment, course_section)
    json
  end

  def sis_assignment_course_json(course)
    json = api_json(course, nil, nil, API_SIS_ASSIGNMENT_COURSE_JSON_OPTS)
    json[:sis_id] = json.delete(:sis_source_id)
    json
  end

  def add_sis_assignment_override_json(json, assignment, course_section)
    assignment_overrides = active_assignment_overrides_for(assignment)
    return unless assignment_overrides
    override = assignment_overrides.detect do |assignment_override|
      assignment_override.set_type == 'CourseSection' && assignment_override.set_id == course_section.id
    end
    return if override.nil?

    override_json = api_json(override, nil, nil, API_SIS_ASSIGNMENT_OVERRIDES_JSON_OPTS)
    override_json[:override_title] = override_json.delete(:title)
    json[:override] = override_json
  end

  private def include_in_final_grade(assignment)
    !(assignment.omit_from_final_grade? || assignment.grading_type == 'not_graded')
  end

  private def active_course_sections_for(context)
    if context.respond_to?(:active_course_sections) && context.association(:active_course_sections).loaded?
      context.active_course_sections
    elsif context.respond_to?(:course_sections) && context.association(:course_sections).loaded?
      context.course_sections.select(&:active?)
    end
  end

  private def active_assignment_overrides_for(assignment)
    if assignment.association(:active_assignment_overrides).loaded?
      assignment.active_assignment_overrides
    elsif assignment.association(:assignment_overrides).loaded?
      assignment.assignment_overrides.select(&:active?)
    end
  end
end
