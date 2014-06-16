module DataFixup::FixIncorrectPublishedStatesOnQuizzesAndAssignments
  def self.run
    while Assignment.where(workflow_state: %w(available active)).limit(1000).update_all(workflow_state: 'published') > 0; end
    while Quizzes::Quiz.where(workflow_state: 'active').limit(1000).update_all(workflow_state: 'available') > 0; end
  end
end
