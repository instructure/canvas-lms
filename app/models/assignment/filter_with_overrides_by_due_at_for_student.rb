#
# Copyright (C) 2015 - present Instructure, Inc.
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
class Assignment::FilterWithOverridesByDueAtForStudent
  # this module provides the public method #filter_assignments
  include Assignment::FilterWithOverridesByDueAt

  def initialize(assignments:, grading_period:, student:)
    @assignments = assignments
    @grading_period = grading_period
    @student = student

    if AssignmentOverrideApplicator.should_preload_override_students?(@assignments, @student, "filter_with_overrides")
      AssignmentOverrideApplicator.preload_assignment_override_students(@assignments, @student)
    end
  end

  private
  attr_reader :assignments, :grading_period, :student

  def due_at_nil_and_last_grading_period?(assignment)
    return false unless grading_period.last?
    return assignment.due_at.nil? if no_active_overrides?(assignment)

    override_dates = override_dates_for_student(assignment)
    if override_dates.empty?
      assignment.due_at.nil? && assigned_to_everyone_else?(assignment)
    else
      override_dates.any?(&:nil?)
    end
  end

  def find_due_at(assignment)
    most_lenient_due_at(assignment)
  end

  def assigned_to_everyone_else?(assignment)
    !assignment.only_visible_to_overrides?
  end

  def most_lenient_due_at(assignment)
    date_to_use = assignment.due_at if assigned_to_everyone_else?(assignment)

    if any_active_overrides?(assignment)
      override_dates = override_dates_for_student(assignment)
      return nil if override_dates.any?(&:nil?)

      most_lenient_date = override_dates.max
      date_to_use = most_lenient_date if most_lenient_date
    end
    milliseconds_to_zero(date_to_use)
  end

  def override_dates_for_student(assignment)
    student_overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(assignment, @student)
    student_overrides.map(&:due_at)
  end
end
