class RemoveIntegrationType < ActiveRecord::Migration
  tag :postdeploy

  def up
    remove_column :context_external_tools, :integration_type
  end

  def down
    add_column :context_external_tools, :integration_type, :string
    add_index :context_external_tools, [:context_id, :context_type, :integration_type], :name => "external_tools_integration_type", :algorithm => :concurrently
  end
end
