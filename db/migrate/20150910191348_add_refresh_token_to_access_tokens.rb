class AddRefreshTokenToAccessTokens < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :access_tokens, :crypted_refresh_token, :string
    add_index :access_tokens, [:crypted_refresh_token], :unique => true
  end

  def self.down
    remove_column :access_tokens, :crypted_refresh_token
  end
end
