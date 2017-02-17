class AddIndexToContentTagsLearningOutcomeId < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    add_index :content_tags, :learning_outcome_id, :algorithm => :concurrently, :where => "learning_outcome_id IS NOT NULL"
  end

  def self.down
    remove_index :content_tags, :column => :learning_outcome_id
  end
end
