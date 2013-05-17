class AddOtpToUsers < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :users, :otp_secret_key_enc, :string
    add_column :users, :otp_secret_key_salt, :string
    add_column :users, :otp_communication_channel_id, :integer, :limit => 8
  end

  def self.down
    remove_column :users, :otp_communication_channel_id
    remove_column :users, :otp_secret_key_salt
    remove_column :users, :otp_secret_key_enc
  end
end
