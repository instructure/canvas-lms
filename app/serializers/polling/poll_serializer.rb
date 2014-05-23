module Polling
  class PollSerializer < Canvas::APISerializer
    root :poll

    attributes :id, :question, :description, :total_results, :created_at

    has_many :poll_choices, embed: :ids

    def_delegators :@controller, :api_v1_poll_choices_url
    def_delegators :object, :total_results

    def poll_choices_url
      api_v1_poll_choices_url(object)
    end

    def filter(keys)
      if object.grants_right?(current_user, session, :update)
        student_keys + teacher_keys
      else
        student_keys
      end
    end

    private

    def teacher_keys
      [:total_results]
    end

    def student_keys
      [:id, :question, :description, :created_at]
    end
  end
end
