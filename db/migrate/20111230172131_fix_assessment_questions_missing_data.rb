class FixAssessmentQuestionsMissingData < ActiveRecord::Migration
  
  def self.up
    Quizzes::QuizQuestionDataFixer.send_later_if_production_enqueue_args(:fix_quiz_questions_with_bad_data, :priority => Delayed::LOWER_PRIORITY, :max_attempts => 1)
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
  
end
