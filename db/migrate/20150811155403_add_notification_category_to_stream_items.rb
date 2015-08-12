class AddNotificationCategoryToStreamItems < ActiveRecord::Migration
  tag :predeploy
  disable_ddl_transaction!

  def up
    add_column :stream_items, :notification_category, :string
    add_index :stream_items, :notification_category, algorithm: :concurrently
  end

  def down
    remove_index :stream_items, :notification_category
    remove_column :stream_items, :notification_category
  end
end
