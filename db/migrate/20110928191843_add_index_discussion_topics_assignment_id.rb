class AddIndexDiscussionTopicsAssignmentId < ActiveRecord::Migration
  def self.up
    add_index :discussion_topics, [:assignment_id]
  end

  def self.down
    remove_index :discussion_topics, [:assignment_id]
  end
end
