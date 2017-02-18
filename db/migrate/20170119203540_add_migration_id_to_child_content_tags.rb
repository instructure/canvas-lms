class AddMigrationIdToChildContentTags < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :master_courses_child_content_tags, :migration_id, :string
    add_index :master_courses_child_content_tags, :migration_id, :name => "index_child_content_tags_on_migration_id"
  end
end
