class AddUpdatePayloadToLtiToolProxy < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :lti_tool_proxies, :update_payload, :text
  end
end
