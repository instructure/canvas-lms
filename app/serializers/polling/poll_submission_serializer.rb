module Polling
  class PollSubmissionSerializer < Canvas::APISerializer
    attributes :id, :poll_choice_id
  end
end
