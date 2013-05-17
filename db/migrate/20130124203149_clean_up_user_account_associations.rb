class CleanUpUserAccountAssociations < ActiveRecord::Migration
  tag :predeploy
  self.transactional = false

  def self.up
    # clean up garbage data
    UserAccountAssociation.where(:user_id => nil).delete_all
    # we don't have any of these in production, but just in case...
    UserAccountAssociation.where(:account_id => nil).delete_all

    # clean up dups by recalculating
    user_ids = UserAccountAssociation.
        select(:user_id).
        uniq.
        group(:user_id, :account_id).
        having("COUNT(*)>1").
        map(&:user_id)
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
