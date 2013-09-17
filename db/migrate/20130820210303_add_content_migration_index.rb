class AddContentMigrationIndex < ActiveRecord::Migration
  tag :postdeploy
  self.transactional = false

  def self.up
    add_index :content_migrations, :context_id, concurrently: true
  end

  def self.down
    remove_index :content_migrations, :context_id
  end
end
