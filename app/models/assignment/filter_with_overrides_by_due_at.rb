# API Filter Assignments by due_at and respect overrides
#
# Returns a list of assignments that have been filtered by assignment
# due_at and assignment_overrides due_at fields. For example: if any
# due_at fields fall within the date range then then corresponding
# assignment is included.
#
# @argument assignments [ActiveRecord::Relation]
#
# @argument start_date [DateTime]

# @argument end_date [DateTime]
#
# @argument differentiated_assignments [Boolean]
#
# @public assignments
#
# @return [ Assignment ] assignments An array of assignments
#
# @example
#   Assignment::FilterWithoutOverridesByDueAt.new(
#     assignments: @context.assignments,
#     grading_period: grading_period
#     differentiated_assignments: @context.feature_enabled?(:differentiated_assignments)
#   )
#

class Assignment::FilterWithOverridesByDueAt
  def initialize(assignments:, grading_period:, differentiated_assignments:)
    @assignments = assignments
    @differentiated_assignments = differentiated_assignments
    @grading_period = grading_period
  end

  # @returns [Assignments]
  def filter_assignments
    assignments.select do |assignment|
      filter_criteria(assignment).any?
    end
  end

  private
  attr_reader :assignments, :grading_period

  def filter_criteria(assignment)
    [
      differentiated_assignments_and_any_assignment_overrides?(assignment) &&
        last_grading_period_and_any_overrides_with_due_at_nil?(assignment),

      differentiated_assignments_and_any_assignment_overrides?(assignment) &&
        any_overrides_in_date_range?(assignment),

      last_grading_period_and_assignment_due_at_nil?(assignment),

      in_date_range_end_inclusive?(assignment)
    ]
  end

  def differentiated_assignments_and_any_assignment_overrides?(assignment)
    differentiated_assignments? && assignment.assignment_overrides.any?
  end

  def last_grading_period_and_any_overrides_with_due_at_nil?(assignment)
    last_grading_period? && any_overrides_with_due_at_nil?(assignment)
  end

  def last_grading_period_and_assignment_due_at_nil?(assignment)
    last_grading_period? && assignment.due_at.nil?
  end

  def in_date_range_end_inclusive?(assignment_or_override)
    return false if assignment_or_override.due_at.nil?

    grading_period.start_date < assignment_or_override.due_at &&
      assignment_or_override.due_at <= grading_period.end_date
  end

  def differentiated_assignments?
    @differentiated_assignments
  end

  def last_grading_period?
    @grading_period.last?
  end

  def any_overrides_in_date_range?(assignment)
    assignment.assignment_overrides.any? do |override|
      in_date_range_end_inclusive?(override)
    end
  end

  def any_overrides_with_due_at_nil?(assignment)
    assignment.assignment_overrides.any? do |override|
      override.due_at.nil?
    end
  end
end
