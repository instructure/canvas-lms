class AddQuizRegradeForeignKeys < ActiveRecord::Migration[4.2]
  tag :predeploy
  def self.up
    add_foreign_key_if_not_exists :quiz_regrades, :users
    add_foreign_key_if_not_exists :quiz_regrades, :quizzes

    add_foreign_key_if_not_exists :quiz_regrade_runs, :quiz_regrades

    add_foreign_key_if_not_exists :quiz_question_regrades, :quiz_regrades
    add_foreign_key_if_not_exists :quiz_question_regrades, :quiz_questions
  end

  def self.down
    remove_foreign_key_if_exists :quiz_regrades, :users
    remove_foreign_key_if_exists :quiz_regrades, :quizzes

    remove_foreign_key_if_exists :quiz_regrade_runs, :quiz_regrades

    remove_foreign_key_if_exists :quiz_question_regrades, :quiz_regrades
    remove_foreign_key_if_exists :quiz_question_regrades, :quiz_questions
  end
end
