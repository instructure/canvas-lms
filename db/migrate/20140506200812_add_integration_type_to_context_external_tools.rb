class AddIntegrationTypeToContextExternalTools < ActiveRecord::Migration
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    add_column :context_external_tools, :integration_type, :string
    add_index :context_external_tools, [:context_id, :context_type, :integration_type], :name => "external_tools_integration_type", :algorithm => :concurrently
  end

  def self.down
    remove_column :context_external_tools, :integration_type
    remove_index :context_external_tools, :name => "external_tools_integration_type"
  end
end
