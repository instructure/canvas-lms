class AddMigrationIdIndexToAttachments < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!
  tag :postdeploy

  def change
    add_index :attachments, [:context_id, :context_type, :migration_id],
      where: "migration_id IS NOT NULL", name: "index_attachments_on_context_and_migration_id", algorithm: :concurrently
  end
end
