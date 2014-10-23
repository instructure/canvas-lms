module DataFixup
  class ChangeGradedSurveySubmissionsToNotNeedGrading

    def self.run
      Quizzes::Quiz.where("quizzes.quiz_type NOT IN ('practice_quiz', 'assignment')").active.find_in_batches(batch_size: 200) do |group|
        subs = Quizzes::QuizSubmission.where(quiz_id: group, workflow_state: 'pending_review')
        subs.each do |qsub|
          qsub.update_attribute(:workflow_state, 'complete')
        end
        Submission.where(quiz_submission_id: subs, workflow_state: 'pending_review').each do |sub|
          sub.update_attribute(:workflow_state, 'graded')
        end
      end
    end
  end
end
