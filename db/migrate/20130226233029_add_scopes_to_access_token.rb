class AddScopesToAccessToken < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :access_tokens, :scopes, :text
    add_column :access_tokens, :remember_access, :boolean
  end

  def self.down
    remove_column :access_tokens, :scopes
    remove_column :access_tokens, :remember_access
  end
end
