class ChangeToolProxySecretType < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    change_column :lti_tool_proxies, :shared_secret, :text
  end

  def self.down
    change_column :lti_tool_proxies, :shared_secret, :string
  end
end
