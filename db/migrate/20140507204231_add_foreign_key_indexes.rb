class AddForeignKeyIndexes < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_index :content_exports, :attachment_id, algorithm: :concurrently
    add_index :content_migrations, :attachment_id, where: 'attachment_id IS NOT NULL', algorithm: :concurrently
    add_index :content_migrations, :exported_attachment_id, where: 'exported_attachment_id IS NOT NULL', algorithm: :concurrently
    add_index :content_migrations, :overview_attachment_id, where: 'overview_attachment_id IS NOT NULL', algorithm: :concurrently
    add_index :discussion_entries, :attachment_id, where: 'attachment_id IS NOT NULL', algorithm: :concurrently
    add_index :discussion_topics, :attachment_id, where: 'attachment_id IS NOT NULL', algorithm: :concurrently
  end

  def self.down
    remove_index :content_exports, :attachment_id
    remove_index :content_migrations, :attachment_id
    remove_index :content_migrations, :exported_attachment_id
    remove_index :content_migrations, :overview_attachment_id
    remove_index :discussion_entries, :attachment_id
    remove_index :discussion_topics, :attachment_id
  end
end
