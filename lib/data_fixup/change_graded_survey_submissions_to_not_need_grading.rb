module DataFixup
  class ChangeGradedSurveySubmissionsToNotNeedGrading

    def self.run
      Quiz.where("quizzes.quiz_type NOT IN ('practice_quiz', 'assignment')").active.find_ids_in_ranges do |first_id, last_id|
        subs = QuizSubmission.where(quiz_id: first_id..last_id).
          where(workflow_state: 'pending_review')

        subs.update_all(workflow_state: 'complete')
        Submission.where(quiz_submission_id: subs,
                         workflow_state: 'pending_review').
                      update_all(workflow_state: 'graded')
      end

    end
  end
end
