module Types
  # TODO: move this into SubmissionFilterInputType when 1.8 lands
  DEFAULT_SUBMISSION_STATES = %w[submitted pending_review graded]

  SubmissionFilterInputType = GraphQL::InputObjectType.define do
    name "SubmissionFilter"

    argument :states, types[!SubmissionStateType], default_value: DEFAULT_SUBMISSION_STATES
  end
end
