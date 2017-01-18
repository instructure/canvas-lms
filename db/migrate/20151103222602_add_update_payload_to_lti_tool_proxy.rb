class AddUpdatePayloadToLtiToolProxy < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :lti_tool_proxies, :update_payload, :text
  end
end
