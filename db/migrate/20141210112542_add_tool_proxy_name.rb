class AddToolProxyName < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :lti_tool_proxies, :name, :string
    add_column :lti_tool_proxies, :description, :string
  end

  def self.down
    remove_column :lti_tool_proxies, :name
    remove_column :lti_tool_proxies, :description
  end
end
