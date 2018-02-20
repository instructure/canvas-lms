module Types
  CourseType = GraphQL::ObjectType.define do
    name "Course"

    implements GraphQL::Relay::Node.interface
    interfaces [Interfaces::TimestampInterface]

    global_id_field :id
    field :_id, !types.ID, "legacy canvas id", property: :id
    field :name, !types.String
    field :courseCode, types.String,
      "course short name",
      property: :course_code
    field :state, !CourseWorkflowState,
      property: :workflow_state

    connection :assignmentGroupsConnection, AssignmentGroupType.connection_type, property: :assignment_groups

    connection :assignmentsConnection do
      type AssignmentType.connection_type
      resolve -> (course, _, ctx) {
        Assignments::ScopedToUser.new(course, ctx[:current_user]).scope
      }
    end

    connection :sectionsConnection do
      type SectionType.connection_type
      resolve -> (course, _, ctx) {
        course.active_course_sections.
          order(CourseSection.best_unicode_collation_key('name'))
      }
    end

    connection :usersConnection do
      type UserType.connection_type

      argument :userIds, types[!types.ID],
        "only include users with the given ids",
        prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("User")

      resolve ->(course, args, ctx) {
        if course.grants_any_right?(ctx[:current_user], ctx[:session],
            :read_roster, :view_all_grades, :manage_grades)
          scope = UserSearch.scope_for(course, ctx[:current_user], include_inactive_enrollments: true)
          scope = scope.where(users: {id: args[:userIds]}) if args[:userIds].present?
          scope
        else
          nil
        end
      }
    end

    connection :gradingPeriodsConnection, GradingPeriodType.connection_type do
      resolve ->(course, _, _) {
        GradingPeriod.for(course).order(:start_date)
      }
    end

    connection :submissionsConnection, SubmissionType.connection_type do
      description "all the submissions for assignments in this course"

      argument :studentIds, !types[!types.ID], "Only return submissions for the given students.",
        prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("User")
      argument :orderBy, types[SubmissionOrderInputType]
      argument :filter, SubmissionFilterInputType

      resolve ->(course, args, ctx) {
        current_user = ctx[:current_user]
        session = ctx[:session]
        user_ids = args[:studentIds].map(&:to_i)

        if course.grants_any_right?(current_user, session, :manage_grades, :view_all_grades)
          # TODO: make a preloader for this???
          allowed_user_ids = course.apply_enrollment_visibility(course.all_student_enrollments, current_user).pluck(:user_id)
          allowed_user_ids &= user_ids
        elsif course.grants_right?(current_user, session, :read_grades)
          allowed_user_ids = user_ids & [current_user.id]
        else
          allowed_user_ids = []
        end

        submissions = Submission.active.joins(:assignment).where(
          user_id: allowed_user_ids,
          assignment_id: course.assignments.published,
          workflow_state: (args[:filter] || {})[:states] || DEFAULT_SUBMISSION_STATES
        )

        (args[:orderBy] || []).each { |order|
          submissions = submissions.order("#{order[:field]} #{order[:direction]}")
        }

        submissions
      }
    end

    connection :groupsConnection, GroupType.connection_type, resolve: ->(course, _, ctx) {
      # TODO: share this with accounts when groups are added there
      if course.grants_right?(ctx[:current_user], nil, :read_roster)
        course.groups.active
          .order(GroupCategory::Bookmarker.order_by, Group::Bookmarker.order_by)
          .eager_load(:group_category)
      else
        nil
      end
    }

    field :permissions, CoursePermissionsType do
      description "returns permission information for the current user in this course"
      resolve ->(course, _, ctx) {
        Loaders::CoursePermissionsLoader.for(
          course,
          current_user: ctx[:current_user], session: ctx[:session]
        )
      }
    end
  end

  SubmissionOrderInputType = GraphQL::InputObjectType.define do
    name "SubmissionOrderCriteria"
    argument :field, !GraphQL::EnumType.define {
      name "SubmissionOrderField"
      value "_id", value: "id"
      value "gradedAt", value: "graded_at"
    }
    argument :direction, GraphQL::EnumType.define {
      name "OrderDirection"
      value "ascending", value: "ASC"
      value "descending", value: "DESC NULLS LAST"
    }
  end

  CourseWorkflowState = GraphQL::EnumType.define do
    name "CourseWorkflowState"
    description "States that Courses can be in"
    value "created"
    value "claimed"
    value "available"
    value "completed"
    value "deleted"
  end
end
