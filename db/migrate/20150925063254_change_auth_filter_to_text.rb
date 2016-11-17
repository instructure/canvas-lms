class ChangeAuthFilterToText < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    change_column :account_authorization_configs, :auth_filter, :text
  end

  def self.down
    change_column :account_authorization_configs, :auth_filter, :string
  end
end
