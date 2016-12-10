class AddScoreBeforeRegradeToQuizSubmission < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :quiz_submissions, :score_before_regrade, :float
  end

  def self.down
    remove_column :quiz_submissions, :score_before_regrade
  end
end
