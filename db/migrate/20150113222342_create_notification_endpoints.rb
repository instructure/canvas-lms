class CreateNotificationEndpoints < ActiveRecord::Migration
  tag :predeploy

  def self.up
    create_table :notification_endpoints do |t|
      t.integer :access_token_id, limit: 8, null: false
      t.string :token, null: false
      t.string :arn, null: false
      t.timestamps null: true
    end
    add_index :notification_endpoints, :access_token_id
    add_foreign_key :notification_endpoints, :access_tokens
  end

  def self.down
    drop_table :notification_endpoints
  end
end
