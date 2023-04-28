# frozen_string_literal: true

module Interfaces::AssignmentsConnectionInterface
  include Interfaces::BaseInterface

  class AssignmentFilterInputType < Types::BaseInputObject
    graphql_name "AssignmentFilter"
    argument :grading_period_id, ID, <<~MD, required: false
      only return assignments for the given grading period. Defaults to
      the current grading period. Pass `null` to return all assignments
      (irrespective of the assignment's grading period)
    MD
  end

  def assignments_scope(course, grading_period_id, has_grading_periods = nil)
    assignments = Assignments::ScopedToUser.new(course, current_user).scope
    if grading_period_id
      assignments
        .joins(:submissions)
        .where(submissions: { grading_period_id: grading_period_id })
        .distinct
    elsif has_grading_periods
      # this is the case where a grading_period_id was not passed *and*
      # we are outside of any grading period (so we return nothing)
      assignments.none
    else
      assignments
    end
  end

  field :assignments_connection,
        ::Types::AssignmentType.connection_type,
        <<~MD,
          returns a list of assignments.

          **NOTE**: for courses with grading periods, this will only return grading
          periods in the current course; see `AssignmentFilter` for more info.
          In courses with grading periods that don't have students, it is necessary
          to *not* filter by grading period to list assignments.
        MD
        null: true do
    argument :filter, AssignmentFilterInputType, required: false
  end

  def assignments_connection(filter: {}, course:)
    if filter.key?(:grading_period_id)
      apply_order(
        assignments_scope(course, filter[:grading_period_id])
      )
    else
      Loaders::CurrentGradingPeriodLoader.load(course)
                                         .then do |gp, has_grading_periods|
        apply_order(
          assignments_scope(course, gp&.id, has_grading_periods)
        )
      end
    end
  end

  def apply_order(assignments)
    # we could force the types that implement assignment_scope to implement
    # this method but i don't think there's going to be any more and this seems
    # a lot more straigthforward
    case self
    when Types::AssignmentGroupType
      assignments.except(:order).ordered
    when Types::CourseType
      assignments
        .joins(:assignment_group).
        # this +select+ is necessary because the assignments scope may be DISTINCT
        select("assignments.*, assignment_groups.position AS group_position")
        .reorder(:group_position, :position, :id)
    end
  end
  private :apply_order
end
