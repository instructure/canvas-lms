module Types
  SubmissionStateType = GraphQL::EnumType.define do
    name "SubmissionState"

    value "submitted"
    value "unsubmitted"
    value "pending_review"
    value "graded"
    value "deleted"
  end
end
