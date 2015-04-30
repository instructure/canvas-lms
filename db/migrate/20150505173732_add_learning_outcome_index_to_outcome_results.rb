class AddLearningOutcomeIndexToOutcomeResults < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def up
    add_index :learning_outcome_results, :learning_outcome_id, algorithm: :concurrently, where: "learning_outcome_id IS NOT NULL"
  end

  def down
    remove_index :learning_outcome_results, :learning_outcome_id
  end
end
