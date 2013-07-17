class ChangeLearningOutcomeGroupIndex < ActiveRecord::Migration
  tag :postdeploy
  self.transactional = false

  def self.up
    remove_index :learning_outcome_groups, [:context_id, :context_type]
    add_index :learning_outcome_groups, [:context_id, :context_type], :concurrently => true
  end

  def self.down
    remove_index :learning_outcome_groups, [:context_id, :context_type]
    add_index :learning_outcome_groups, [:context_id, :context_type], :concurrently => true, :conditions => "learning_outcome_group_id IS NULL"
  end
end
