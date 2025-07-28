# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

module Factories
  def assignment_override_model(opts = {})
    override_for = opts.delete(:set)
    assignment = opts.delete(:assignment) || opts.delete(:quiz) || opts[:context_module] || assignment_model(opts)
    attrs = assignment_override_valid_attributes.merge(opts)
    attrs[:due_at_overridden] = opts.key?(:due_at)
    attrs[:lock_at_overridden] = opts.key?(:lock_at)
    attrs[:unlock_at_overridden] = opts.key?(:unlock_at)
    attrs[:set] = override_for if override_for
    @override = assignment.assignment_overrides.create!(attrs)
  end

  def assignment_override_valid_attributes
    { title: "Some Title" }
  end

  def create_section_override_for_assignment(assignment_or_quiz, opts = {})
    opts_with_default = opts.reverse_merge({
                                             due_at: 2.days.from_now,
                                             due_at_overridden: true,
                                             set_type: "CourseSection",
                                             course_section: assignment_or_quiz.context.default_section,
                                             title: "test override",
                                             workflow_state: "active"
                                           })

    if assignment_or_quiz.is_a?(SubAssignment) && assignment_or_quiz.context.discussion_checkpoints_enabled?
      override_params = {
        set_type: opts_with_default[:set_type],
        set_id: opts_with_default[:course_section].id,
        due_at: opts_with_default[:due_at],
        unlock_at: opts[:unlock_at],
        lock_at: opts[:lock_at]
      }
      service = Checkpoints::SectionOverrideCreatorService.new(checkpoint: assignment_or_quiz, override: override_params)
      ao = service.call
    else
      ao = assignment_or_quiz.assignment_overrides.build
      ao.due_at = opts_with_default[:due_at]
      ao.due_at_overridden = opts_with_default[:due_at_overridden]
      ao.set_type = opts_with_default[:set_type]
      ao.set = opts_with_default[:course_section]
      ao.title = opts_with_default[:title]
      ao.workflow_state = opts_with_default[:workflow_state]
      ao.save!
    end

    ao
  end
  alias_method :create_section_override_for_quiz, :create_section_override_for_assignment

  def create_group_override_for_assignment(assignment, opts = {})
    if opts[:group]
      group = opts[:group]
      group.group_category
    else
      group_category = opts[:group_category] || group_category(context: assignment.context)
      group_opts = opts.merge({ context: group_category })
      group = group(group_opts)
    end

    group.add_user(opts[:user], "accepted", opts[:moderator]) if opts[:user]
    opts_with_default = opts.reverse_merge({
                                             due_at: 2.days.from_now,
                                             due_at_overridden: true,
                                             set_type: "Group",
                                             group:,
                                             title: "group override",
                                             workflow_state: "active"
                                           })

    if assignment.is_a?(SubAssignment) && assignment.context.discussion_checkpoints_enabled?
      # Use the new service for sub-assignments
      override_params = {
        set_type: opts_with_default[:set_type],
        set_id: opts_with_default[:group].id,
        due_at: opts_with_default[:due_at],
        unlock_at: opts[:unlock_at],
        lock_at: opts[:lock_at]
      }
      service = Checkpoints::GroupOverrideCreatorService.new(checkpoint: assignment, override: override_params)
      ao = service.call
    else
      # Use the existing logic for regular assignments
      ao = assignment.assignment_overrides.build
      ao.due_at = opts_with_default[:due_at]
      ao.due_at_overridden = opts_with_default[:due_at_overridden]
      ao.set_type = opts_with_default[:set_type]
      ao.set = opts_with_default[:group]
      ao.title = opts_with_default[:title]
      ao.workflow_state = opts_with_default[:workflow_state]
      ao.save!
    end

    ao
  end

  def create_adhoc_override_for_assignment(assignment_or_quiz, users, opts = {})
    if assignment_or_quiz.is_a?(SubAssignment) && assignment_or_quiz.context.discussion_checkpoints_enabled?
      override_params = {
        student_ids: Array.wrap(users).map(&:id),
        due_at: opts[:due_at]
      }
      service = Checkpoints::AdhocOverrideCreatorService.new(checkpoint: assignment_or_quiz, override: override_params)
      @override = service.call
    else
      @override = assignment_override_model(opts.merge(assignment: assignment_or_quiz))
      @override.set = nil
      @override.set_type = "ADHOC"
      @override.due_at = opts[:due_at]
      @override.save!

      users = Array.wrap(users)
      users.each do |user|
        @override_student = @override.assignment_override_students.build
        @override_student.user = user
        @override_student.save!
      end
    end

    @override
  end

  def create_course_override_for_assignment(assignment_or_quiz, opts = {})
    if assignment_or_quiz.is_a?(SubAssignment) && assignment_or_quiz.context.discussion_checkpoints_enabled?
      override_params = {
        student_ids: Array.wrap(users).map(&:id),
        due_at: opts[:due_at]
      }
      service = Checkpoints::CourseOverrideCreatorService.new(checkpoint: assignment_or_quiz, override: override_params)
      @override = service.call
    else
      @override = assignment_override_model(opts.merge(assignment: assignment_or_quiz))
      @override.set = assignment_or_quiz.context
      @override.set_type = "Course"
      @override.due_at = opts[:due_at]
      @override.save!
    end

    @override
  end

  def create_mastery_paths_override_for_assignment(assignment_or_quiz, opts = {})
    mastery_paths_opts = {
      assignment: assignment_or_quiz,
      set_type: AssignmentOverride::SET_TYPE_NOOP,
      set_id: AssignmentOverride::NOOP_MASTERY_PATHS
    }
    assignment_override_model(opts.merge(mastery_paths_opts))
  end
end
