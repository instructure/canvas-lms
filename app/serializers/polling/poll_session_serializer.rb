module Polling
  class PollSessionSerializer < Canvas::APISerializer
    attributes :id, :is_published, :has_public_results, :results, :course_id,
      :course_section_id, :created_at, :poll_id, :poll_submissions, :has_submitted

    def_delegators :object, :results, :poll

    # has_many relationships with embedded objects doesn't work, so we override it this way
    def poll_submissions
      @poll_submissions ||= begin
                              if can_view_results?
                                submissions = object.poll_submissions
                              else
                                submissions = object.poll_submissions.where(user_id: current_user)
                              end
                              submissions.map do |submission|
                                Polling::PollSubmissionSerializer.new(submission, controller: @controller, scope: @scope, root: false)
                              end
                            end
    end

    def has_submitted
      object.has_submission_from?(current_user)
    end

    def filter(keys)
      if can_view_results?
        student_keys + teacher_keys
      else
        student_keys
      end
    end

    private

    def can_view_results?
      object.has_public_results? || poll.grants_right?(current_user, session, :update)
    end

    def teacher_keys
      [:has_public_results, :results]
    end

    def student_keys
      [:id, :is_published, :course_id, :course_section_id, :created_at, :poll_id, :has_submitted, :poll_submissions]
    end
  end
end
