class AddSubmittedAtToLearningOutcomeResult < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :learning_outcome_results, :submitted_at, :datetime
  end

end
