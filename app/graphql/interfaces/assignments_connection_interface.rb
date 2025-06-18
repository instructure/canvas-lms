# frozen_string_literal: true

module Interfaces::AssignmentsConnectionInterface
  include Interfaces::BaseInterface

  class AssignmentFilterInputType < Types::BaseInputObject
    graphql_name "AssignmentFilter"
    argument :user_id, ID, <<~MD, required: false
      only return assignments for the given user. Defaults to
      the current user.
    MD
    argument :grading_period_id, ID, <<~MD, required: false
      only return assignments for the given grading period. Defaults to
      the current grading period. Pass `null` to return all assignments
      (irrespective of the assignment's grading period)
    MD
    argument :search_term, String, <<~MD, required: false
      only return assignments whose title matches this search term
    MD
    argument :submission_types, [Types::AssignmentSubmissionType], <<~MD, required: false
      only return assignments for the given submission types. Defaults to
      all.
    MD
  end

  def assignments_scope(course, grading_period_id, has_grading_periods = nil, user_id = nil, search_term = nil, submission_types = nil)
    scoped_user = user_id.nil? ? current_user : User.find(user_id)
    assignments = Assignments::ScopedToUser.new(course, scoped_user).scope
    unless can_current_user_read_given_user_submissions(course, scoped_user)
      # current_user lacks permissions to view the submissions of the scoped_user
      return assignments.none
    end

    # Apply search term filter if provided
    if search_term.present?
      assignments = assignments.where(Assignment.wildcard(:title, search_term))
    end

    # Apply hide_in_gradebook filter if the feature flag is enabled
    if Account.site_admin.feature_enabled?(:hide_zero_point_quizzes_option)
      assignments = assignments.not_hidden_in_gradebook
    end

    if submission_types.present?
      # Filter assignments where any of the requested submission_types overlap with the
      # assignment's submission_types. The assignments.submission_types column is a comma-separated
      # string (e.g., 'online_upload,online_quiz'). To efficiently filter, we convert this string
      # to a PostgreSQL text[] array on the fly using string_to_array. The overlap operator (&&)
      # checks if any of the requested submission_types are present in the array. Both sides are
      # explicitly cast to text[] to avoid type errors (e.g., text[] && text[]).
      assignments = assignments.where(
        "string_to_array(assignments.submission_types, ',')::text[] && ARRAY[?]::text[]",
        submission_types
      )
    end

    if grading_period_id
      assignments
        .joins(:submissions)
        .where(submissions: { grading_period_id: })
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

  def assignments_connection(course:, filter: {})
    if filter.key?(:grading_period_id) || filter.key?(:user_id)
      apply_assignment_order(
        assignments_scope(course, filter[:grading_period_id], nil, filter[:user_id], filter[:search_term], filter[:submission_types])
      )
    else
      Loaders::CurrentGradingPeriodLoader.load(course)
                                         .then do |gp, has_grading_periods|
        apply_assignment_order(
          assignments_scope(course, gp&.id, has_grading_periods, filter[:user_id], filter[:search_term], filter[:submission_types])
        )
      end
    end
  end

  def can_current_user_read_given_user_submissions(course, user)
    is_current_user = user.id == current_user.id
    course_submission_read_permissions = course.grants_any_right?(current_user, session, :read_as_admin, :manage_grades)
    observer_permissions = ObserverEnrollment.observed_students(course, current_user, include_restricted_access: false).keys.any? { |observed_user| observed_user.id == user.id }
    is_current_user || course_submission_read_permissions || observer_permissions
  end

  def apply_assignment_order(assignments)
    # we could force the types that implement assignment_scope to implement
    # this method but i don't think there's going to be any more and this seems
    # a lot more straigthforward
    case self
    when Types::AssignmentGroupType
      assignments.except(:order).ordered
    when Types::CourseType
      assignments
        .joins(:assignment_group)
        # this +select+ is necessary because the assignments scope may be DISTINCT
        .select("assignments.*, assignment_groups.position AS group_position")
        .reorder(:group_position, :position, :id)
    end
  end
  private :apply_assignment_order
end
