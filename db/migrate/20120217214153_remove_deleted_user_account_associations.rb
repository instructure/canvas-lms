class RemoveDeletedUserAccountAssociations < ActiveRecord::Migration
  def self.up
    UserAccountAssociation.delete_all("user_id IN (SELECT id FROM users WHERE workflow_state IN ('deleted', 'creation_pending'))")
  end

  def self.down
  end
end
