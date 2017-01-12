class AddUniqueIndexToGroupMemberships < ActiveRecord::Migration
  tag :postdeploy

  def up
    DataFixup::RemoveDuplicateGroupMemberships.run
    add_index :group_memberships, [:group_id, :user_id], :unique => true, :algorithm => :concurrently, :where => "workflow_state <> 'deleted'"
  end

  def down
    remove_index :group_memberships, [:group_id, :user_id]
  end
end
