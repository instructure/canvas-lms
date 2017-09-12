module Types
  AssignmentType = GraphQL::ObjectType.define do
    name "Assignment"

    implements GraphQL::Relay::Node.interface

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
  end
end
