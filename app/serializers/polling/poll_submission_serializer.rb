module Polling
  class PollSubmissionSerializer < Canvas::APISerializer
    root :poll_submission
    attributes :id, :poll_session_id, :poll_choice_id, :user_id, :created_at
  end
end
