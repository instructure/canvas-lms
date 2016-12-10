class AddAttachmentToContentMigration < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :content_migrations, :exported_attachment_id, :integer, :limit => 8
  end

  def self.down
    remove_column :content_migrations, :exported_attachment_id
  end
end
