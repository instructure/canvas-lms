class AddMigrationSelectionForExternalTools < ActiveRecord::Migration[4.2]
  tag :predeploy
  def self.up
    add_column :context_external_tools, :has_migration_selection, :boolean
    add_index :context_external_tools, [:context_id, :context_type, :has_migration_selection], :name => "external_tools_migration_selection"
  end

  def self.down
    remove_column :context_external_tools, :has_migration_selection
    remove_index :context_external_tools, :name => "external_tools_migration_selection"
  end
end
