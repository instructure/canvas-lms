class AddLtiToolProxyIdToLtiMessageHandler < ActiveRecord::Migration[4.2]
  tag :predeploy
  def up
    add_column :lti_message_handlers, :tool_proxy_id, :bigint
    add_foreign_key :lti_message_handlers, :lti_tool_proxies, column: :tool_proxy_id
    add_index :lti_message_handlers, [:tool_proxy_id]
  end

  def down
    remove_column :lti_message_handlers, :tool_proxy_id, :bigint
  end
end
