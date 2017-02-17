class DropBodyAndSmsBodyColumns < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    remove_column :notifications, :body
    remove_column :notifications, :sms_body
    ::ActiveRecord::Base.connection.schema_cache.clear!
    Notification.reset_column_information
  end

  def self.down
    create_column :notifications, :body, :text
    create_column :notifications, :sms_body, :text
  end
end
