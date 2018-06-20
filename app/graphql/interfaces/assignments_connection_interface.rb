module Interfaces::AssignmentsConnectionInterface
  include GraphQL::Schema::Interface

  class AssignmentFilterInputType < Types::BaseInputObject
    graphql_name "AssignmentFilter"
    argument :gradingPeriodId, ID, <<~DESC, required: false
      only return assignments for the given grading period. Defaults to
      the current grading period. Pass `null` to return all assignments
      (irrespective of the assignment's grading period)
    DESC
  end

  def assignments_scope(course, grading_period_id, has_grading_periods = nil)
    assignments = Assignments::ScopedToUser.new(course, current_user).scope
    if grading_period_id
      assignments.
        joins(:submissions).
        where(submissions: {grading_period_id: grading_period_id}).
        distinct
    elsif has_grading_periods
      # this is the case where a grading_period_id was not passed *and*
      # we are outside of any grading period (so we return nothing)
      assignments.none
    else
      assignments
    end
  end

  field :assignments_connection, ::Types::AssignmentType.connection_type,
    <<~DOC,
      returns a list of assignments.

      **NOTE**: for courses with grading periods, this will only return grading
      periods in the current course; see `AssignmentFilter` for more info.
      In courses with grading periods that don't have students, it is necessary
      to *not* filter by grading period to list assignments.
    DOC
    null: true do
      argument :filter, AssignmentFilterInputType, required: false
    end

  def assignments_connection(filter: {}, course:)
    if filter.key?(:grading_period_id)
      assignments_scope(course, filter[:grading_period_id])
    else
      Loaders::CurrentGradingPeriodLoader.load(course)
        .then do |gp, has_grading_periods|
        assignments_scope(course, gp&.id, has_grading_periods)
      end
    end
  end
end
