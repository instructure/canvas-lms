class AddSubmittedAtToLearningOutcomeResult < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :learning_outcome_results, :submitted_at, :datetime
  end

end
