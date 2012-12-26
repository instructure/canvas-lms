class AddCantGoBackToQuiz < ActiveRecord::Migration
  tag :predeploy
  def self.up
    add_column :quizzes, :cant_go_back, :boolean
    Quiz.reset_column_information
  end

  def self.down
    remove_column :quizzes, :cant_go_back
  end
end
