class RemoveScribdAccount < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    drop_table :scribd_accounts
    remove_column :attachments, :scribd_account_id
    remove_column :attachments, :scribd_user
  end

  def self.down
    create_table "scribd_accounts", :force => true do |t|
      t.integer  "scribdable_id", :limit => 8
      t.string   "scribdable_type"
      t.string   "uuid"
      t.string   "workflow_state"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "scribd_accounts", ["scribdable_id", "scribdable_type"], :name => "index_scribd_accounts_on_scribdable_id_and_scribdable_type"

    add_column :attachments, :scribd_account_id, :integer, :limit => 8
    add_column :attachments, :scribd_user, :string

  end
end
