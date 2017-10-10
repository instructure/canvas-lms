module Types
  SubmissionType = GraphQL::ObjectType.define do
    name "Submission"

    implements GraphQL::Relay::Node.interface
    interfaces [Interfaces::TimestampInterface]

    global_id_field :id
    # not doing a legacy canvas id since they aren't used in the rest api

    field :assignment, AssignmentType,
      resolve: ->(s, _, _) { Loaders::IDLoader.for(Assignment).load(s.assignment_id) }

    field :user, UserType, resolve: ->(s, _, _) { Loaders::IDLoader.for(User).load(s.user_id) }

    field :score, types.Float, resolve: SubmissionHelper.protect_submission_grades(:score)

    field :grade, types.String, resolve: SubmissionHelper.protect_submission_grades(:grade)

    field :excused, types.Boolean,
      "excused assignments are ignored when calculating grades",
      property: :excused?

    field :submittedAt, TimeType, property: :submitted_at
    field :gradedAt, TimeType, property: :graded_at
  end

  class SubmissionHelper
    def self.protect_submission_grades(attr)
      ->(submission, _, ctx) {
        submission.user_can_read_grade?(ctx[:current_user], ctx[:session]) ?
          submission.send(attr) :
          nil
      }
    end
  end
end
