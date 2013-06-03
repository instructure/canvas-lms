module BroadcastPolicies
  class QuizSubmissionPolicy
    attr_reader :quiz_submission

    def initialize(quiz_submission)
      @quiz_submission = quiz_submission
    end

    def should_dispatch_submission_graded?
      quiz_is_accepting_messages? &&
      quiz_submission.user.student_enrollments.map(&:course_id).include?(quiz.context_id) &&
      (quiz_submission.changed_state_to(:complete) || manually_graded)
    end

    def should_dispatch_submission_grade_changed?
      quiz_is_accepting_messages? &&
      quiz_submission.submission.graded_at &&
      quiz_submission.changed_in_state(:complete, :fields => [:score])
    end

    private
    def quiz
      quiz_submission.quiz
    end

    def quiz_is_accepting_messages?
      quiz_submission &&
      quiz.assignment &&
      !quiz.muted? &&
      quiz.context.available? &&
      !quiz.deleted?
    end

    def manually_graded
      quiz_submission.changed_in_state(:pending_review, :fields => [:fudge_points])
    end
  end
end
