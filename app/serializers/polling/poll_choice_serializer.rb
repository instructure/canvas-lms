module Polling
  class PollChoiceSerializer < Canvas::APISerializer
    root :poll_choice

    attributes :id, :text, :is_correct

    has_one :poll, embed: :id

    def_delegators :object, :poll
    def_delegators :@controller, :api_v1_poll_url

    def filter(keys)
      if is_teacher?
        student_keys + teacher_keys
      else
        student_keys
      end
    end

    def poll_url
      api_v1_poll_url(poll)
    end

    private
    def is_teacher?
      poll.grants_right?(current_user, session, :update)
    end

    def teacher_keys
      [:is_correct]
    end

    def student_keys
      [:id, :text]
    end
  end
end
