class AddDomainSpecificToAccountNotifications < ActiveRecord::Migration[5.0]
  tag :predeploy
  disable_ddl_transaction!

  def up
    add_column :account_notifications, :domain_specific, :boolean
    change_column_default(:account_notifications, :domain_specific, false)
    DataFixup::BackfillNulls.run(AccountNotification, :domain_specific, default_value: false)
    change_column_null(:account_notifications, :domain_specific, false)
  end

  def down
    remove_column :account_notifications, :domain_specific
  end
end
