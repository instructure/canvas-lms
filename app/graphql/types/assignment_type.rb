module Types
  AssignmentType = GraphQL::ObjectType.define do
    name "Assignment"

    implements GraphQL::Relay::Node.interface
    interfaces [Interfaces::TimestampInterface]

    global_id_field :id
    field :_id, !types.ID, "legacy canvas id", property: :id

    field :name, types.String

    field :position, types.Int,
      "determines the order this assignment is displayed in in its assignment group"
    field :description, types.String

    field :pointsPossible, types.Float,
      "the assignment is out of this many points",
      property: :points_possible

    field :dueAt, types.String,
      "when this assignment is due",
      property: :due_at

    field :state, !AssignmentState, property: :workflow_state

    field :assignmentGroup, AssignmentGroupType, resolve: ->(assignment, _, _) {
      Loaders::AssociationLoader.for(Assignment, :assignment_group)
        .load(assignment)
        .then { assignment.assignment_group }
    }

    field :quiz, Types::QuizType, resolve: -> (assignment, _, _) {
      Loaders::AssociationLoader.for(Assignment, :quiz)
        .load(assignment)
        .then { assignment.quiz }
    }

    field :discussion, Types::DiscussionType, resolve: -> (assignment, _, _) {
      Loaders::AssociationLoader.for(Assignment, :discussion_topic)
        .load(assignment)
        .then { assignment.discussion_topic }
    }

    field :htmlUrl, UrlType, resolve: ->(assignment, _, ctx) {
      Rails.application.routes.url_helpers.course_assignment_url(
        course_id: assignment.context_id,
        id: assignment.id,
        host: ctx[:request].host_with_port
      )
    }

    field :needsGradingCount, types.Int do
      # NOTE: this query (as it exists right now) is not batch-able.
      # make this really expensive cost-wise?
      resolve ->(assignment, _, ctx) do
        Assignments::NeedsGradingCountQuery.new(
          assignment,
          ctx[:current_user]
          # TODO course proxy stuff
          # (actually for some reason not passing along a course proxy doesn't
          # seem to matter)
        ).count
      end
    end

    field :course, Types::CourseType, resolve: -> (assignment, _, _) {
      # course is polymorphicly associated with assignment through :context
      # it could also be queried by assignment.assignment_group.course
      Loaders::AssociationLoader.for(Assignment, :context)
        .load(assignment)
        .then { assignment.context }
    }

    field :assignmentGroup, AssignmentGroupType, resolve: ->(assignment, _, _) {
      Loaders::AssociationLoader.for(Assignment, :assignment_group)
        .load(assignment)
        .then { assignment.assignment_group }
    }

    field :onlyVisibleToOverrides, types.Boolean,
      "specifies that this assignment is only assigned to students for whom an
       `AssignmentOverride` applies.",
      property: :only_visible_to_overrides

    connection :submissionsConnection, SubmissionType.connection_type do
      description "submissions for this assignment"
      resolve ->(assignment, _, ctx) {
        current_user = ctx[:current_user]
        session = ctx[:session]
        course = assignment.course

        if course.grants_any_right?(current_user, session, :manage_grades, :view_all_grades)
          # a user can see all submissions
          assignment.submissions.where.not(workflow_state: "unsubmitted")
        elsif course.grants_right?(current_user, session, :read_grades)
          # a user can see their own submission
          assignment.submissions.where(user_id: current_user.id).where.not(workflow_state: "unsubmitted")
        end
      }
    end
  end

  AssignmentState = GraphQL::EnumType.define do
    name "AssignmentState"
    description "States that an Assignment can be in"
    value "unpublished"
    value "published"
    value "deleted"
  end
end
