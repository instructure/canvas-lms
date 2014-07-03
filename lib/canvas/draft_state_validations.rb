module Canvas
  module DraftStateValidations
    def self.included(base)
      base.class_eval do
        validate :validate_draft_state_change, :if => :workflow_state_changed?
      end
    end

    def validate_draft_state_change
      old_draft_state, new_draft_state = self.changes['workflow_state']
      return if old_draft_state == new_draft_state
      if new_draft_state == 'unpublished' && has_student_submissions?
        self.errors.add :workflow_state, I18n.t('#quizzes.cant_unpublish_when_students_submit',
                                                "Can't unpublish if there are student submissions")
      end
    end
  end
end
