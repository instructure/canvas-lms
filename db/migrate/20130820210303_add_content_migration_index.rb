class AddContentMigrationIndex < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_index :content_migrations, :context_id, concurrently: true
  end

  def self.down
    remove_index :content_migrations, :context_id
  end
end
