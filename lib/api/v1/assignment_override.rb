#
# Copyright (C) 2011 Instructure, Inc.
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

module Api::V1::AssignmentOverride
  include Api::V1::Json

  def assignment_override_json(override)
    fields = [:id, :assignment_id, :title]
    fields.concat([:due_at, :all_day, :all_day_date]) if override.due_at_overridden
    fields << :unlock_at if override.unlock_at_overridden
    fields << :lock_at if override.lock_at_overridden
    api_json(override, @current_user, session, :only => fields).tap do |json|
      case override.set_type
      when 'ADHOC'
        json[:student_ids] = override.assignment_override_students.map(&:user_id)
      when 'Group'
        json[:group_id] = override.set_id
      when 'CourseSection'
        json[:course_section_id] = override.set_id
      end
    end
  end

  def assignment_overrides_json(overrides)
    overrides.map{ |override| assignment_override_json(override) }
  end

  def assignment_override_collection(assignment, include_students=false)
    overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(assignment, @current_user)
    if include_students
      ActiveRecord::Associations::Preloader.new(overrides, :assignment_override_students).run
    end
    overrides
  end

  def find_assignment_override(assignment, set_or_id)
    overrides = assignment_override_collection(assignment)
    return nil if overrides.empty? || set_or_id.nil?
    case set_or_id
    when CourseSection, Group
      overrides.detect do |o|
        o.set_type == set_or_id.class.to_s &&
        o.set_id == set_or_id.id # maybe FIXME
      end
    else
      overrides.detect { |o| o.id == set_or_id.to_i }
    end
  end

  def find_group(assignment, group_id)
    scope = Group.active.where(:context_type => 'Course').where("group_category_id IS NOT NULL")
    scope = scope.where(:context_id => assignment.context_id, :group_category_id => assignment.group_category_id) if assignment
    group = scope.find(group_id)
    raise ActiveRecord::RecordNotFound unless group.grants_right?(@current_user, session, :read)
    group
  end

  def find_section(context, section_id)
    scope = CourseSection.active
    scope = scope.where(:course_id => context) if context
    section = api_find(scope, section_id)
    raise ActiveRecord::RecordNotFound unless section.grants_right?(@current_user, session, :read)
    section
  end

  def interpret_assignment_override_data(assignment, data, set_type=nil)
    data ||= {}
    return {}, ["invalid override data"] unless data.is_a?(Hash)

    # validate structure of parameters
    override_data = {}
    errors = []

    if !set_type && data[:student_ids]
      set_type = 'ADHOC'
    end

    if set_type == 'ADHOC' && data[:student_ids]
      # require the ids to be a list
      student_ids = data[:student_ids]
      if !student_ids.is_a?(Array) || student_ids.empty?
        errors << "invalid student_ids #{student_ids.inspect}"
        students = []
      else
        # look up the students
        students = api_find_all(assignment.context.students_visible_to(@current_user), student_ids).uniq

        # make sure they were all valid
        found_ids = students.map{ |s| [
          s.id.to_s,
          ("sis_login_id:#{s.pseudonym.unique_id}" if s.pseudonym),
          ("hex:sis_login_id:#{s.pseudonym.unique_id.to_s.unpack('H*')}" if s.pseudonym),
          ("sis_user_id:#{s.pseudonym.sis_user_id}" if s.pseudonym && s.pseudonym.sis_user_id),
          ("hex:sis_user_id:#{s.pseudonym.sis_user_id.to_s.unpack('H*')}" if s.pseudonym && s.pseudonym.sis_user_id)
        ]}.flatten.compact
        bad_ids = student_ids.map(&:to_s) - found_ids
        errors << "unknown student ids: #{bad_ids.inspect}" unless bad_ids.empty?
      end
      override_data[:students] = students
    end

    if !set_type && data.has_key?(:group_id)
      if !assignment.group_category_id
        # don't recognize group_id for non-group assignments
        errors << "group_id is not valid for non-group assignments"
      else
        set_type = 'Group'

        # look up the group
        begin
          group = find_group(assignment, data[:group_id])
        rescue ActiveRecord::RecordNotFound
          errors << "unknown group id #{data[:group_id].inspect}"
        end
        override_data[:group] = group
      end
    end

    if !set_type && data.has_key?(:course_section_id)
      set_type = 'CourseSection'

      # look up the section
      begin
        section = find_section(assignment.context, data[:course_section_id])
      rescue ActiveRecord::RecordNotFound
        errors << "unknown section id #{data[:course_section_id].inspect}"
      end
      override_data[:section] = section
    end

    errors << "one of student_ids, group_id, or course_section_id is required" if !set_type && errors.empty?

    if set_type == 'ADHOC' && data.has_key?(:title)
      override_data[:title] = data[:title]
    end

    # collect override values
    [:due_at, :unlock_at, :lock_at].each do |field|
      if data.has_key?(field)
        if data[field].blank?
          # override value of nil/'' is meaningful
          override_data[field] = nil
        elsif value = Time.zone.parse(data[field].to_s)
          override_data[field] = value
        else
          errors << "invalid #{field} #{data[field].inspect}"
        end
      end
    end

    errors = nil if errors.empty?
    return override_data, errors
  end

  def update_assignment_override_without_save(override, override_data)
    if override_data.has_key?(:students)
      override.set = nil
      override.set_type = 'ADHOC'

      defunct_student_ids = override.new_record? ?
        Set.new :
        override.assignment_override_students.map(&:user_id).to_set

      override_data[:students].each do |student|
        if defunct_student_ids.include?(student.id)
          defunct_student_ids.delete(student.id)
        else
          # link will be saved with the override
          link = override.assignment_override_students.build
          link.assignment_override = override
          link.user = student
        end
      end

      unless defunct_student_ids.empty?
        override.assignment_override_students.
          where(:user_id => defunct_student_ids.to_a).
          delete_all
      end
    end

    if override_data.has_key?(:group)
      override.set = override_data[:group]
    end

    if override_data.has_key?(:section)
      override.set = override_data[:section]
    end

    if override.set_type == 'ADHOC'
      override.title = override_data[:title] ||
                         override.title_from_students(override_data[:students]) ||
                         override.title
    end

    [:due_at, :unlock_at, :lock_at].each do |field|
      if override_data.has_key?(field)
        override.send("override_#{field}", override_data[field])
      else
        override.send("clear_#{field}_override")
      end
    end
  end

  def update_assignment_override(override, override_data)
    override.transaction do
      update_assignment_override_without_save(override, override_data)
      override.save!
    end
    return true
  rescue ActiveRecord::RecordInvalid
    return false
  end

  def batch_update_assignment_overrides(assignment, overrides_params)
    override_param_ids = overrides_params.map{ |ov| ov[:id] }
    existing_overrides = assignment.assignment_overrides.active

    remaining_overrides = destroy_defunct_overrides(assignment, override_param_ids, existing_overrides)
    ActiveRecord::Associations::Preloader.new(remaining_overrides, :assignment_override_students).run

    overrides = overrides_params.map do |override_params|
      override = get_override_from_params(override_params, assignment, remaining_overrides)
      data, errors = interpret_assignment_override_data(assignment, override_params, override.set_type)
      if errors
        override.errors.add(errors)
      else
        update_assignment_override_without_save(override, data)
      end
      override
    end

    raise ActiveRecord::RecordInvalid.new(assignment) unless assignment.valid?

    overrides.each(&:save!)
  end

  def destroy_defunct_overrides(assignment, override_param_ids, existing_overrides)
    defunct_override_ids =  existing_overrides.map(&:id) - override_param_ids.map(&:to_i)
    return existing_overrides if defunct_override_ids.empty?

    assignment.assignment_overrides.where(:id => defunct_override_ids).destroy_all
    existing_overrides.reject{|override| defunct_override_ids.include?(override.id)}
  end
  private :destroy_defunct_overrides

  def get_override_from_params(override_params, assignment, potential_overrides)
    potential_overrides.detect { |ov|
      ov.id == override_params[:id].to_i
    } || assignment.assignment_overrides.build.tap { |ov|
      ov.dont_touch_assignment = true
    }
  end
  private :get_override_from_params

  def deserialize_overrides(overrides)
    if overrides.is_a?(Hash)
      return unless overrides.keys.all?{ |k| k.to_i.to_s == k.to_s }
      indices = overrides.keys.sort_by(&:to_i)
      return unless indices.map(&:to_i) == (0...indices.size).to_a
      overrides = indices.map{ |index| overrides[index] }
    else
      overrides
    end
  end
end
