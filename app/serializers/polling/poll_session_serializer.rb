module Polling
  class PollSessionSerializer < Canvas::APISerializer
    root :poll_session

    attributes :id, :is_published, :has_public_results, :results, :course_id, :course_section_id, :created_at

    def_delegators :object, :results, :poll

    def filter(keys)
      if poll.grants_right?(current_user, session, :update) || object.has_public_results?
        student_keys + teacher_keys
      else
        student_keys
      end
    end

    private

    def teacher_keys
      [:has_public_results, :results]
    end

    def student_keys
      [:id, :is_published, :course_id, :course_section_id, :created_at]
    end
  end
end
