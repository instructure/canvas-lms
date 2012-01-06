class FixAssessmentQuestionsMissingData < ActiveRecord::Migration
  
  def self.up
    QuizQuestionDataFixer.send_later_enqueue_args(:fix_quiz_questions_with_bad_data, :priority => Delayed::LOWER_PRIORITY, :max_attempts => 1)
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
  
end
