class RemoveDeletedUserAccountAssociations < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    UserAccountAssociation.where("user_id IN (SELECT id FROM #{User.quoted_table_name} WHERE workflow_state IN ('deleted', 'creation_pending'))").delete_all
  end

  def self.down
  end
end
