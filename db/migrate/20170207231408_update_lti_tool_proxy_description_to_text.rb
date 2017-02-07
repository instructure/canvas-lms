class UpdateLtiToolProxyDescriptionToText < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    change_column :lti_tool_proxies, :description, :text
  end

  def down
    change_column :lti_tool_proxies, :description, :string
  end
end
