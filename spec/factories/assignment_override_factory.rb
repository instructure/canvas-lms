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

module Factories
  def assignment_override_model(opts={})
    override_for = opts.delete(:set)
    assignment = opts.delete(:assignment) || opts.delete(:quiz) || assignment_model(opts)
    attrs = assignment_override_valid_attributes.merge(opts)
    attrs[:due_at_overridden] = opts.key?(:due_at)
    attrs[:lock_at_overridden] = opts.key?(:lock_at)
    attrs[:unlock_at_overridden] = opts.key?(:unlock_at)
    attrs[:set] = override_for if override_for
    @override = factory_with_protected_attributes(assignment.assignment_overrides, attrs)
  end

  def assignment_override_valid_attributes
    { :title => "Some Title" }
  end

  def create_section_override_for_assignment(assignment_or_quiz, opts={})
    ao = assignment_or_quiz.assignment_overrides.build
    ao.due_at = opts[:due_at] || 2.days.from_now
    ao.set_type = "CourseSection"
    #make sure the default due date is overridden with our override due date
    ao.due_at_overridden = true
    ao.set = opts[:course_section] || assignment_or_quiz.context.default_section
    ao.title = "test override"
    ao.save!
    ao
  end
  alias :create_section_override_for_quiz :create_section_override_for_assignment

  def create_adhoc_override_for_assignment(assignment_or_quiz, users, opts={})
    assignment_override_model(opts.merge(assignment: assignment_or_quiz))
    @override.set = nil
    @override.set_type = 'ADHOC'
    @override.save!

    users = Array.wrap(users)
    users.each do |user|
      @override_student = @override.assignment_override_students.build
      @override_student.user = user
      @override_student.save!
    end
    @override
  end

  def create_mastery_paths_override_for_assignment(assignment_or_quiz, opts={})
    mastery_paths_opts = {
      assignment: assignment_or_quiz,
      set_type: AssignmentOverride::SET_TYPE_NOOP,
      set_id: AssignmentOverride::NOOP_MASTERY_PATHS
    }
    assignment_override_model(opts.merge(mastery_paths_opts))
  end
end
