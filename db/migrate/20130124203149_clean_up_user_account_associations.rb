class CleanUpUserAccountAssociations < ActiveRecord::Migration
  tag :predeploy
  self.transactional = false

  def self.up
    # clean up garbage data
    UserAccountAssociation.delete_all(:user_id => nil)
    # we don't have any of these in production, but just in case...
    UserAccountAssociation.delete_all(:account_id => nil)

    # clean up dups by recalculating
    user_ids = UserAccountAssociation.find(:all, :select => 'DISTINCT user_id',
       :group => 'user_id, account_id', :having => 'COUNT(*) > 1').map(&:user_id)
    User.update_account_associations(user_ids)

    # add a unique index
    add_index :user_account_associations, [:user_id, :account_id], :unique => true, :concurrently => true
    # remove the non-unique index that's now covered by the unique index
    remove_index :user_account_associations, :user_id
  end

  def self.down
    add_index :user_account_associations, :user_id, :concurrently => true
    remove_index :user_account_associations, [:user_id, :account_id]
  end
end
