class ChangeLearningOutcomeGroupIndex < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    remove_index :learning_outcome_groups, [:context_id, :context_type]
    add_index :learning_outcome_groups, [:context_id, :context_type], :algorithm => :concurrently
  end

  def self.down
    remove_index :learning_outcome_groups, [:context_id, :context_type]
    add_index :learning_outcome_groups, [:context_id, :context_type], :algorithm => :concurrently, :where => "learning_outcome_group_id IS NULL"
  end
end
