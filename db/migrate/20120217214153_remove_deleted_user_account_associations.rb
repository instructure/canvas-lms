class RemoveDeletedUserAccountAssociations < ActiveRecord::Migration
  def self.up
    UserAccountAssociation.where("user_id IN (SELECT id FROM users WHERE workflow_state IN ('deleted', 'creation_pending'))").delete_all
  end

  def self.down
  end
end
