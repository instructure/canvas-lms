class AddIndexToContentTagsLearningOutcomeId < ActiveRecord::Migration
  tag :predeploy
  self.transactional = false

  def self.up
    add_index :content_tags, :learning_outcome_id, :concurrently => true, :conditions => "learning_outcome_id IS NOT NULL"
  end

  def self.down
    remove_index :content_tags, :column => :learning_outcome_id
  end
end
