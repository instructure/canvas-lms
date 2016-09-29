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
    only: %i(id name sis_source_id group_weight).freeze
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

  API_SIS_ASSIGNMENT_USER_LEVEL_JSON_OPTS = {
      only: %i(id name sis_user_id).freeze
  }.freeze

  API_SIS_ASSIGNMENT_USER_LEVEL_OVERRIDES_JSON_OPTS = {
      only: %i(assignment_override_id due_at).freeze
  }.freeze

  def sis_assignments_json(assignments)
    assignments.map { |a| sis_assignment_json(a) }
  end

  private

  def sis_assignment_json(assignment)
    json = api_json(assignment, nil, nil, API_SIS_ASSIGNMENT_JSON_OPTS)
    json[:course_id] = assignment.context_id if assignment.context_type == 'Course'
    json[:submission_types] = json.delete(:submission_types_array)
    json[:include_in_final_grade] = include_in_final_grade(assignment)
    user_overrides = active_user_level_assignment_overrides_for(assignment)
    add_sis_assignment_group_json(assignment, json)
    add_sis_course_sections_json(assignment, json)
    add_sis_user_overrides_json(assignment, json) if !user_overrides.nil? && user_overrides.count > 0
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

  def add_sis_user_overrides_json(assignment, json)
    users = active_user_level_assignment_overrides_for(assignment)
    return if users.nil?
    json.merge!(user_overrides: sis_assignment_users_json(users, assignment))
  end

  # Deals with a case where the same assignment override
  # is assigned to more than one student.
  def extract_multiple_user_overrides(user_overrides, assignment)
    override_info = []
    matching_pairs = []

    user_overrides.each { |user| override_info.push(extract_user_override_info(user)) }
    info_copy = override_info
    override_info.each do |override|
      info_copy.each do |copy|
        if override[:id] != copy[:id] && override[:override_id] == copy[:override_id]
          matching_pairs.push([override[:id], copy[:id]].sort())
        end
      end
    end

    pairs = get_unique_pairs(matching_pairs)
    return user_overrides if pairs.nil?
    get_associated_user_info(user_overrides, pairs, assignment)
  end

  def get_unique_pairs(matching_pairs)
    found_pairs = []

    pairs = matching_pairs.map do |numbers|
      pair = numbers.uniq - found_pairs
      found_pairs += pair
      pair
    end

    pairs.reject!(&:empty?)
  end

  def get_associated_user_info(users, unique_pairs, assignment)
    overrides = active_assignment_overrides_for(assignment)
    associated_users = []
    valid_user_overrides = users.to_a
    unique_pairs.each do |pair|
      if pair.class == Array
        temp = []
        temp_due_at = nil
        pair.each do |id|
          user = users.find(id)
          temp_due_at = overrides.find(user.assignment_override_id).due_at
          temp.push({'id' => user.user_id,
                     'name' => user.user.name,
                     'sis_user_id' => user.user.pseudonym.sis_user_id}) if user && id == user.id
          valid_user_overrides.delete_if { |u| u.id == id }
        end
        temp.push({'due_at' => temp_due_at})
        associated_users.push(temp)
      else
        user = users.find(pair)
        associated_users.push({'id' => user.user_id,
                               'name' => user.user.name,
                               'sis_user_id' => user.user.pseudonym.sis_user_id})  if user && pair == user.id
        valid_user_overrides.delete_if { |u| u.id == pair }
      end
    end
    associated_users.concat valid_user_overrides
  end

  def extract_user_override_info(user)
    {id: user.id, user_id: user.user_id, override_id: user.assignment_override_id}
  end

  def sis_assignment_users_json(users, assignment)
    users = extract_multiple_user_overrides(users, assignment)
    users.map { |s| sis_assignment_user_json(s, assignment) }
  end

  def sis_assignment_course_sections_json(course_sections, assignment)
    if assignment.only_visible_to_overrides
      section_ids = active_assignment_overrides_for(assignment).map { |o| o.set_id if o.set_type == 'CourseSection' }
      section_ids = Set.new(section_ids.compact)
      course_sections = course_sections.select { |section| section_ids.include?(section.id) }
    end

    course_sections.map { |s| sis_assignment_course_section_json(s, assignment) }
  end

  def sis_assignment_user_json(user, assignment)
    if user.class == Array
      json = {}
      *json[:id], json[:override] = user
    else
      # This merge! is required so we can obtain the name from the user object
      # and the rest of the attributes from the pseudonym object
      sis_assignment_user_level_json = api_json(user.user, nil, nil, API_SIS_ASSIGNMENT_USER_LEVEL_JSON_OPTS)
      sis_assignment_pseudonym_level_json = api_json(user.user.pseudonym, nil, nil, API_SIS_ASSIGNMENT_USER_LEVEL_JSON_OPTS)
      json = sis_assignment_user_level_json.merge!(sis_assignment_pseudonym_level_json)
      add_sis_assignment_user_level_override_json(json, assignment, user)
    end
    json
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

  def include_in_final_grade(assignment)
    !(assignment.omit_from_final_grade? || assignment.grading_type == 'not_graded')
  end

  def add_sis_assignment_user_level_override_json(json, assignment, user)
    assignment_overrides = active_assignment_overrides_for(assignment)
    return unless assignment_overrides

    override = assignment_overrides.detect do |assignment_override|
      assignment_override.set_type == 'ADHOC' &&
      assignment_override.assignment_id == user.assignment_id &&
      assignment_override.id == user.assignment_override_id
    end
    return if override.nil?

    override_json = api_json(override, nil, nil, API_SIS_ASSIGNMENT_USER_LEVEL_OVERRIDES_JSON_OPTS)
    json[:override] = override_json
  end

  def active_course_sections_for(context)
    if context.respond_to?(:active_course_sections) && context.association(:active_course_sections).loaded?
      context.active_course_sections
    elsif context.respond_to?(:course_sections) && context.association(:course_sections).loaded?
      context.course_sections.select(&:active?)
    end
  end

  def active_assignment_overrides_for(assignment)
    if assignment.association(:active_assignment_overrides).loaded?
      assignment.active_assignment_overrides
    elsif assignment.association(:assignment_overrides).loaded?
      assignment.assignment_overrides.select(&:active?)
    end
  end

  def active_user_level_assignment_overrides_for(assignment)
    if assignment.assignment_override_students
      assignment.assignment_override_students
    end
  end
end
