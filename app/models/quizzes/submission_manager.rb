module Quizzes
  class SubmissionManager

    def initialize(quiz)
      @quiz = quiz
    end

    def find_or_create_submission(user, temporary=false, state=nil)
      s = nil
      state ||= 'untaken'
      @quiz.shard.activate do
        Quizzes::QuizSubmission.unique_constraint_retry do
          if !user.is_a?(::User)
            query_hash = { temporary_user_code: "#{user.to_s}" }
          elsif temporary
            query_hash = { temporary_user_code: "user_#{user.id}" }
          else
            query_hash = { user_id: user.id }
          end

          s = @quiz.quiz_submissions.where(query_hash).first
          s ||= @quiz.quiz_submissions.build(generate_build_hash(query_hash, user))

          s.workflow_state ||= state
          s.save! if s.changed?
        end
      end
      s
    end

    def self.grade_outstanding_submissions_in_course(user_id, context_id, context_type)
      user = User.find(user_id)
      user.quiz_submissions
        .where('quizzes.context_id=? AND quizzes.context_type=?', context_id, context_type)
        .includes(:quiz)
        .select(&:needs_grading?)
        .each do |quiz_submission|
          Quizzes::SubmissionGrader.new(quiz_submission).grade_submission({
            finished_at: quiz_submission.end_at
          })
        end
    end

    private
    # this is needed because Rails 2 expects a User object instead of an id
    def generate_build_hash(query_hash, user)
      return query_hash unless query_hash[:user_id]
      { user: user}
    end

  end
end
