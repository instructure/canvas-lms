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
module Assignment::FilterWithOverridesByDueAt

  def filter_assignments
    ActiveRecord::Associations::Preloader.new.preload(assignments, :assignment_overrides)
    assignments.select { |assignment| in_grading_period?(assignment) }
  end

  private
  def in_date_range_end_inclusive?(due_at)
    !due_at.nil? && grading_period.in_date_range?(due_at)
  end

  def in_date_range_of_grading_period?(assignment)
    due_at = find_due_at(assignment)
    in_date_range_end_inclusive?(due_at)
  end

  def in_grading_period?(assignment)
    due_at_nil_and_last_grading_period?(assignment) ||
      in_date_range_of_grading_period?(assignment)
  end

  def milliseconds_to_zero(due_at)
    due_at.change(usec: 0) if due_at
  end

  def active_overrides(assignment)
    # using 'select' instead of calling the 'active' scope
    # because we have assignment_overrides eager loaded and
    # we don't want to make additional AR calls.
    @active_assignment_overrides ||= {}
    @active_assignment_overrides[assignment.id] ||=
      assignment.assignment_overrides.select do |override|
        override.workflow_state == 'active'
      end
  end

  def any_active_overrides?(assignment)
    active_overrides(assignment).any?
  end

  def no_active_overrides?(assignment)
    !any_active_overrides?(assignment)
  end
end
