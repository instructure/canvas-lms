module Quizzes
  class SubmissionManager

    def initialize(quiz)
      @quiz = quiz
    end

    def create_or_update_submission(user, temporary=false, state=nil)
      s = nil
      state ||= 'untaken'
      @quiz.shard.activate do
        Quizzes::QuizSubmission.unique_constraint_retry do
          if temporary || !user.is_a?(::User)
            user_code = "#{user.to_s}"
            user_code = "user_#{user.id}" if user.is_a?(::User)
            s = @quiz.quiz_submissions.where(temporary_user_code: user_code).first
            s ||= @quiz.quiz_submissions.build(temporary_user_code: user_code)
            s.workflow_state ||= state
            s.save! if s.changed?
          else
            s = @quiz.quiz_submissions.where(user_id: user).first
            s ||= @quiz.quiz_submissions.build(user: user)
            s.workflow_state ||= state
            s.save! if s.changed?
          end
        end
      end
      s
    end

  end
end
