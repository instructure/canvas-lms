class AddShowCorrectAnswersLastAttemptToQuizzes < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :quizzes, :show_correct_answers_last_attempt, :boolean
  end
end
