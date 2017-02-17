class AddScoreVisibilityToQuizzes < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :quizzes, :show_correct_answers_at, :datetime
    add_column :quizzes, :hide_correct_answers_at, :datetime
  end

  def self.down
    remove_column :quizzes, :hide_correct_answers_at
    remove_column :quizzes, :show_correct_answers_at
  end
end
