class AcceptPendingGroupMemberships < ActiveRecord::Migration
  def self.up
    GroupMembership.where(:workflow_state => 'invited').update_all(:workflow_state => 'accepted')
    GroupMembership.where(:workflow_state => 'requested').update_all(:workflow_state => 'accepted')
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
