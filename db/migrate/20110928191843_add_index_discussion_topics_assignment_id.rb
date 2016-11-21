class AddIndexDiscussionTopicsAssignmentId < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_index :discussion_topics, [:assignment_id]
  end

  def self.down
    remove_index :discussion_topics, [:assignment_id]
  end
end
