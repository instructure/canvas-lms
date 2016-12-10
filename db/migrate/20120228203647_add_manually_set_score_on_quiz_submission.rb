class AddManuallySetScoreOnQuizSubmission < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :quiz_submissions, :manually_scored, :boolean
  end

  def self.down
    remove_column :quiz_submissions, :manually_scored
  end
end
