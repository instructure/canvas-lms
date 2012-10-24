class AddAccessTokenCryptedToken < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :access_tokens, :crypted_token, :string
    add_column :access_tokens, :token_hint, :string
    add_index :access_tokens, [:crypted_token], :unique => true
  end

  def self.down
    remove_column :access_tokens, :crypted_token
    remove_column :access_tokens, :token_hint
  end
end
