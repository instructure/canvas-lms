class AddExternalToolMigrationIdIndex < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!
  tag :postdeploy

  def change
    add_index :context_external_tools, [:context_id, :context_type, :migration_id],
      where: "migration_id IS NOT NULL", name: "index_external_tools_on_context_and_migration_id", algorithm: :concurrently
  end
end
