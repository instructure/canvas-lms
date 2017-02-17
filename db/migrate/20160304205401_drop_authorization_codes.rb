class DropAuthorizationCodes < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    drop_table :authorization_codes
  end

  def down
    create_table "authorization_codes", :force => true do |t|
      t.string   "authorization_code"
      t.string   "authorization_service"
      t.integer  "account_id", :limit => 8
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "associated_account_id", :limit => 8
    end

    add_index "authorization_codes", ["account_id"], :name => "index_authorization_codes_on_account_id"
  end
end
