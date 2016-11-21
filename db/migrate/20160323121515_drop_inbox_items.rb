class DropInboxItems < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    remove_column :users, :unread_inbox_items_count
    drop_table :inbox_items
  end

  def down
    add_column :users, :unread_inbox_items_count, :integer

    create_table "inbox_items" do |t|
      t.integer  "user_id", :limit => 8
      t.integer  "sender_id", :limit => 8
      t.integer  "asset_id", :limit => 8
      t.string   "subject"
      t.string   "body_teaser"
      t.string   "asset_type"
      t.string   "workflow_state"
      t.boolean  "sender"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "context_code"
    end
  end
end
