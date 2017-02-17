class AddOneTimeResultsToQuizzes < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :quizzes, :one_time_results, :boolean
    add_column :quiz_submissions, :has_seen_results, :boolean
  end

  def self.down
    remove_column :quizzes, :one_time_results
    remove_column :quiz_submissions, :has_seen_results
  end
end
