class ChangeToolProxyIdNotNull < ActiveRecord::Migration[4.2]
  tag :postdeploy
  def change
    DataFixup::AddToolProxyToMessageHandler.run
    change_column_null :lti_message_handlers, :tool_proxy_id, :false
  end
end
