class AcceptPendingGroupMemberships < ActiveRecord::Migration
  def self.up
    GroupMembership.update_all({ :workflow_state => 'accepted' }, { :workflow_state => 'invited' })
    GroupMembership.update_all({ :workflow_state => 'accepted' }, { :workflow_state => 'requested' })
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
