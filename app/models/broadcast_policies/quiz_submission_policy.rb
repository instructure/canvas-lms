module BroadcastPolicies
  class QuizSubmissionPolicy
    attr_reader :quiz_submission

    def initialize(quiz_submission)
      @quiz_submission = quiz_submission
    end

    def should_dispatch_submission_graded?
      quiz_is_accepting_messages_for_student? &&
      quiz_submission.user &&
      quiz_submission.user.student_enrollments.map(&:course_id).include?(quiz.context_id) &&
      (quiz_submission.changed_state_to(:complete) || manually_graded)
    end

    def should_dispatch_submission_grade_changed?
      quiz_is_accepting_messages_for_student? &&
      quiz_submission.submission.try(:graded_at) &&
      quiz_submission.changed_in_state(:complete, :fields => [:score]) &&
      user_has_visibility?
    end

    def should_dispatch_submission_needs_grading?
      !quiz.survey? &&
      quiz_is_accepting_messages_for_admin? &&
      quiz_submission.pending_review? &&
      user_has_visibility?
    end

    private
    def quiz
      quiz_submission.quiz
    end

    def quiz_is_accepting_messages_for_student?
      quiz_submission &&
      quiz.assignment &&
      !quiz.muted? &&
      quiz.context.available? &&
      !quiz.deleted?
    end

    def quiz_is_accepting_messages_for_admin?
      quiz_submission &&
        quiz.assignment &&
        quiz.context.available? &&
        !quiz.deleted?
    end

    def manually_graded
      quiz_submission.changed_in_state(:pending_review, :fields => [:fudge_points])
    end

    def user_has_visibility?
      return false if quiz_submission.user_id.nil?
      Quizzes::QuizStudentVisibility.where(quiz_id: quiz.id, user_id: quiz_submission.user_id).any?
    end
  end
end
