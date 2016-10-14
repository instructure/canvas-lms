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

  def assignment_override_json(override, visible_users=nil)
    fields = [:id, :assignment_id, :title]
    fields.concat([:due_at, :all_day, :all_day_date]) if override.due_at_overridden
    fields << :unlock_at if override.unlock_at_overridden
    fields << :lock_at if override.lock_at_overridden
    api_json(override, @current_user, session, :only => fields).tap do |json|
      case override.set_type
      when 'ADHOC'
        if override.preloaded_student_ids
          json[:student_ids] = override.preloaded_student_ids
        else
          json[:student_ids] = if visible_users.present?
                       override.assignment_override_students.where(user_id: visible_users).pluck(:user_id)
                     else
                       override.assignment_override_students.pluck(:user_id)
                     end
        end
      when 'Group'
        json[:group_id] = override.set_id
      when 'CourseSection'
        json[:course_section_id] = override.set_id
      end
    end
  end

  def assignment_overrides_json(overrides, user = nil)
    visible_users_ids = ::AssignmentOverride.visible_enrollments_for(overrides.compact, user).select(:user_id)
    # we most likely already have the student_ids preloaded here because of overridden_for, but just in case
    if overrides.any?{|ov| ov.present? && ov.set_type == 'ADHOC' && !ov.preloaded_student_ids}
      AssignmentOverrideApplicator.preload_student_ids_for_adhoc_overrides(overrides.select{|ov| ov.set_type == 'ADHOC'}, visible_users_ids)
    end
    overrides.map{ |override| assignment_override_json(override, visible_users_ids) if override }
  end

  def assignment_override_collection(assignment, include_students=false)
    overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(assignment, @current_user)
    if include_students
      ActiveRecord::Associations::Preloader.new.preload(overrides, :assignment_override_students)
    end
    overrides
  end

  def find_assignment_override(assignment, set_or_id)
    find_assignment_overrides(assignment, [set_or_id])[0]
  end

  def find_assignment_overrides(assignment, sets_or_ids)
    overrides = assignment_override_collection(assignment)
    sets_or_ids.map do |set_or_id|
      filter_assignment_overrides(overrides, set_or_id)
    end
  end

  def filter_assignment_overrides(overrides, set_or_id)
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

  def find_group(assignment, group_id, group_category_id=nil)
    scope = Group.active.where(:context_type => 'Course').where("group_category_id IS NOT NULL")
    if assignment
      scope = scope.where(
        context_id: assignment.context_id,
        group_category_id: (group_category_id || assignment.group_category_id)
      )
    end
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
        # look up all the active students since the assignment will affect all
        # active students in the course on this override and not just what the
        # teacher can see that were sent in the request object
        students = api_find_all(assignment.context.students.active, student_ids).uniq

        # make sure they were all valid
        found_ids = students.map{ |s| [
          s.id.to_s,
          s.global_id.to_s,
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
      group_category_id = assignment.group_category_id || assignment.discussion_topic.try(:group_category_id)
      if !group_category_id
        # don't recognize group_id for non-group assignments
        errors << "group_id is not valid for non-group assignments"
      else
        set_type = 'Group'
        # look up the group
        begin
          group = find_group(assignment, data[:group_id], group_category_id)
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

  def check_property(object, prop, present, errors, message)
    object.each_with_index.reject do |element, i|
      if element[prop].present? != present
        errors[i] ||= []
        errors[i] << message
      end
    end
  end

  # receives data of shape [{ id: 2, assignment_id: 1, ...update_params }, ... ]
  # responds with data of shape [{ assignment: model, override: model, ...update_params }, ...]
  def interpret_batch_assignment_overrides_data(course, assignment_overrides_data, for_update)
    return nil, ['no assignment override data present'] unless assignment_overrides_data.present?
    return nil, ['must specify an array of overrides'] unless assignment_overrides_data.is_a? Array

    all_errors = Array.new(assignment_overrides_data.length)

    check_property(assignment_overrides_data, 'assignment_id', true, all_errors, 'must specify an assignment id')
    if for_update
      check_property(assignment_overrides_data, 'id', true, all_errors, 'must specify an override id')
    else
      check_property(assignment_overrides_data, 'id', false, all_errors, 'may not specify an override id')
    end
    return nil, all_errors unless all_errors.compact.blank?

    grouped = assignment_overrides_data.group_by {|o| o['assignment_id']}
    assignments = course.active_assignments.where(id: grouped.keys).preload(:assignment_overrides)
    overrides = grouped.map do |assignment_id, overrides_data|
      assignment = assignments.find {|a| a.id.to_s == assignment_id.to_s}
      find_assignment_overrides(assignment, overrides_data.map{|o| o['id']}) if assignment
    end.flatten.compact if for_update

    interpreted = assignment_overrides_data.each_with_index.map do |override_data, i|
      assignment = assignments.find {|a| a.id.to_s == override_data['assignment_id'].to_s}
      unless assignment.present?
        all_errors[i] = ['assignment not found']
        next
      end
      if for_update
        override = overrides.find {|o| o.id.to_s == override_data['id'].to_s}
        unless override.present?
          all_errors[i] = ['override not found']
          next
        end
        set_type = override.set_type
      end

      update_data, errors = interpret_assignment_override_data(assignment, override_data, set_type)
      if errors
        all_errors[i] = errors
        next
      end
      update_data['assignment'] = assignment
      update_data['override'] = override if for_update
      update_data
    end
    all_errors = nil if all_errors.compact.blank?
    [interpreted, all_errors]
  end

  def update_assignment_override_without_save(override, override_data)
    if override_data.has_key?(:students)
      override.set = nil
      override.set_type = 'ADHOC'

      defunct_student_ids = override.new_record? ?
        Set.new :
        override.assignment_override_students.map(&:user_id).to_set

      override.changed_student_ids = Set.new

      override_data[:students].each do |student|
        if defunct_student_ids.include?(student.id)
          defunct_student_ids.delete(student.id)
        else
          # link will be saved with the override
          link = override.assignment_override_students.build
          link.assignment_override = override
          link.user = student
          override.changed_student_ids << student.id
        end
      end

      unless defunct_student_ids.empty?
        override.changed_student_ids.merge(defunct_student_ids)
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
    if override.set_type == 'ADHOC' && override.changed_student_ids.present?
      override.assignment.run_if_overrides_changed_later!(override.changed_student_ids.to_a)
    else
      override.assignment.run_if_overrides_changed_later!
    end
    return true
  rescue ActiveRecord::RecordInvalid
    return false
  end

  # updates only the selected overrides; compare with
  # batch_update_assignment_overrides below, which updates
  # all overrides for assignment
  def update_assignment_overrides(overrides, overrides_data)
    overrides.zip(overrides_data).each do |override, data|
      update_assignment_override_without_save(override, data)
    end
    return false if overrides.find(&:invalid?).present?

    AssignmentOverride.transaction do
      overrides.each(&:save!)
    end
    overrides.map(&:assignment).uniq.each(&:run_if_overrides_changed_later!)
  rescue ActiveRecord::RecordInvalid
    return false
  end

  def invisible_users_and_overrides_for_user(context, user, existing_overrides)
    # get the student overrides the user can't see and ensure those overrides are included
    visible_user_ids = context.enrollments_visible_to(user).select(:user_id)
    invisible_user_ids = context.users.where.not(id: visible_user_ids).pluck(:id)
    invisible_override_ids = existing_overrides.select{ |ov|
      ov.set_type == 'ADHOC' &&
      !ov.visible_student_overrides(visible_user_ids)
    }.map(&:id)
    return invisible_user_ids, invisible_override_ids
  end

  def overrides_after_defunct_removed(assignment, existing_overrides, overrides_params, invisible_override_ids)
    override_param_ids = invisible_override_ids + overrides_params.map{ |ov| ov[:id] }
    remaining_overrides = destroy_defunct_overrides(assignment, override_param_ids, existing_overrides)
    ActiveRecord::Associations::Preloader.new.preload(remaining_overrides, :assignment_override_students)
    remaining_overrides
  end

  def update_override_with_invisible_data(override_params, override, invisible_override_ids, invisible_user_ids)
    return override_params = override if invisible_override_ids.include?(override.id)
    # add back in the invisible students for this override if any found
    hidden_ids = override.assignment_override_students.where(user_id: invisible_user_ids).pluck(:user_id)
    unless hidden_ids.empty?
      override_params[:student_ids] = (override_params[:student_ids] + hidden_ids)
      overrides_size = override_params[:student_ids].size
      override_params[:title] = t({ one: '1 student', other: "%{count} students" }, count: overrides_size)
    end
  end

  # updates all updates for an assignment; compare with
  # update_assignment_overrides below, which updates
  # all overrides for assignment
  def batch_update_assignment_overrides(assignment, overrides_params, user)
    existing_overrides = assignment.assignment_overrides.active
    invisible_user_ids, invisible_override_ids = invisible_users_and_overrides_for_user(
      assignment.context,
      user,
      existing_overrides
    )
    remaining_overrides = overrides_after_defunct_removed(assignment,
                                                          existing_overrides,
                                                          overrides_params,
                                                          invisible_override_ids)

    overrides = overrides_params.map do |override_params|
      override = get_override_from_params(override_params, assignment, remaining_overrides)
      update_override_with_invisible_data(override_params, override, invisible_override_ids, invisible_user_ids)

      data, errors = interpret_assignment_override_data(assignment, override_params, override.set_type)
      if errors
        # add the errors to the assignment so that they are caught on
        # the Api::V1::Assignment#update_api_assignment
        # to enact intended behavior
        assignment.errors.add(:base, errors.join(','))
      else
        update_assignment_override_without_save(override, data)
      end
      override
    end

    raise ActiveRecord::RecordInvalid.new(assignment) unless assignment.valid?
    overrides.each(&:save!)

    assignment.run_if_overrides_changed_later!
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
