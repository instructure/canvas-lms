class AddToolIdToExternalTools < ActiveRecord::Migration[4.2]
  tag :predeploy
  def self.up
    # using tool_id instead of developer_key.id lets us
    # use the same keys as www.eduappcenter.com for
    # tying multiple context_external_tools to the
    # same third-party tool
    add_column :context_external_tools, :tool_id, :string
    add_index :context_external_tools, [:tool_id]
    add_column :developer_keys, :tool_id, :string
    add_index :developer_keys, [:tool_id], :unique => true
  end

  def self.down
    remove_column :context_external_tools, :tool_id
    remove_index :context_external_tools, [:tool_id]
    remove_column :developer_keys, :tool_id
    remove_index :developer_keys, [:tool_id]
  end
end
