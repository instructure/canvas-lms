module Polling
  class PollSessionSerializer < Canvas::APISerializer
    attributes :id, :is_published, :has_public_results, :results, :course_id, :course_section_id, :created_at, :poll_id, :poll_submissions

    def_delegators :object, :results, :poll

    # has_many relationships with embedded objects doesn't work, so we override it this way
    def poll_submissions
      @poll_submissions ||= object.poll_submissions.map do |submission|
        Polling::PollSubmissionSerializer.new(submission, controller: @controller, scope: @scope, root: false)
      end
    end

    def filter(keys)
      if poll.grants_right?(current_user, session, :update) || object.has_public_results?
        student_keys + teacher_keys
      else
        student_keys
      end
    end

    private

    def teacher_keys
      [:has_public_results, :results, :poll_submissions]
    end

    def student_keys
      [:id, :is_published, :course_id, :course_section_id, :created_at, :poll_id]
    end
  end
end
