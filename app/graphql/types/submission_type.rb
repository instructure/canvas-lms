module Types
  SubmissionType = GraphQL::ObjectType.define do
    name "Submission"

    implements GraphQL::Relay::Node.interface
    global_id_field :id
    # not doing a legacy canvas id since they aren't used in the rest api

    field :assignment, AssignmentType,
      resolve: ->(s, _, _) { Loaders::IDLoader.for(Assignment).load(s.assignment_id) }

    field :user, UserType, resolve: ->(s, _, _) { Loaders::IDLoader.for(User).load(s.user_id) }

    field :score, types.Float

    field :grade, types.String

    field :excused, types.Boolean,
      "excused assignments are ignored when calculating grades",
      property: :excused?

    field :submittedAt, TimeType, property: :submitted_at
    field :gradedAt, TimeType, property: :graded_at
  end
end
