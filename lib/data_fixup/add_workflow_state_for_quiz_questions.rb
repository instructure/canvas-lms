module DataFixup

  module AddWorkflowStateForQuizQuestions
    def self.run
      scope = QuizQuestion.where(workflow_state: nil)
      QuizQuestion.find_ids_in_ranges do |first_id, last_id|
        scope.where(id: first_id..last_id).update_all(workflow_state: 'active')
      end
    end
  end
end
