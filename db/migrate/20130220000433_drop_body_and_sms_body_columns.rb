class DropBodyAndSmsBodyColumns < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    remove_column :notifications, :body
    remove_column :notifications, :sms_body
  end

  def self.down
    create_column :notifications, :body, :text
    create_column :notifications, :sms_body, :text
  end
end
