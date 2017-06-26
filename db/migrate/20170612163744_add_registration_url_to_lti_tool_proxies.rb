class AddRegistrationUrlToLtiToolProxies < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :lti_tool_proxies, :registration_url, :text
  end
end
