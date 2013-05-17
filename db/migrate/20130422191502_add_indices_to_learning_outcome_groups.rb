class AddIndicesToLearningOutcomeGroups < ActiveRecord::Migration
  tag :predeploy
  self.transactional = false

  def self.up
    add_index :learning_outcome_groups, [:context_id, :context_type], :concurrently => true, :conditions => { :learning_outcome_group_id => nil }
    add_index :learning_outcome_groups, :learning_outcome_group_id, :concurrently => true, :conditions => "learning_outcome_group_id IS NOT NULL"
  end

  def self.down
    remove_index :learning_outcome_groups, [:context_id, :context_type]
    remove_index :learning_outcome_groups, :learning_outcome_group_id
  end
end
