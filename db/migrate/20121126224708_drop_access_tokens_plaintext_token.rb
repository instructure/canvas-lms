class DropAccessTokensPlaintextToken < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    remove_column :access_tokens, :token
  end

  def self.down
    add_column :access_tokens, :token, :string
  end
end
