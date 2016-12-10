class AddContentMigrationIndex < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_index :content_migrations, :context_id, algorithm: :concurrently
  end

  def self.down
    remove_index :content_migrations, :context_id
  end
end
