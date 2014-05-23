module Polling
  class PollSubmissionSerializer < Canvas::APISerializer
    root :poll_submission

    attributes :id, :poll_choice_id
  end
end
