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
class Assignment::FilterWithOverridesByDueAtForClass
  # this module provides the public method #filter_assignments
  include Assignment::FilterWithOverridesByDueAt

  def initialize(assignments:, grading_period:)
    @assignments = assignments
    @grading_period = grading_period
  end

  private
  attr_reader :assignments, :grading_period

  def due_at_nil_and_last_grading_period?(assignment)
    return false unless grading_period.last?
    return assignment.due_at.nil? if no_active_overrides?(assignment)
    active_overrides(assignment).any? { |override| override.due_at.nil? }
  end

  def find_due_at(assignment)
    due_at = any_active_overrides?(assignment) ? filter_date_from_overrides(assignment) : assignment.due_at
    milliseconds_to_zero(due_at)
  end

  def filter_date_from_overrides(assignment)
    due_ats = active_overrides(assignment).map(&:due_at)
    due_ats << assignment.due_at
    due_ats.compact!
    date_within_period = due_ats.find { |due_at| in_date_range_end_inclusive?(due_at) }
    date_within_period || due_ats.first
  end
end
