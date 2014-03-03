class AddOneQuestionAtATimeToQuiz < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :quizzes, :one_question_at_a_time, :boolean
    Quizzes::Quiz.reset_column_information
  end

  def self.down
    remove_column :quizzes, :one_question_at_a_time
  end
end
