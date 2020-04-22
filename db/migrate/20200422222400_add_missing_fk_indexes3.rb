class AddMissingFkIndexes3 < ActiveRecord::Migration[5.2]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :content_migrations, :child_subscription_id, where: "child_subscription_id IS NOT NULL", algorithm: :concurrently
    add_index :master_courses_migration_results, :child_subscription_id, algorithm: :concurrently
    add_index :master_courses_master_templates, :active_migration_id, where: "active_migration_id IS NOT NULL", algorithm: :concurrently
    add_index :master_courses_master_content_tags, :current_migration_id,
              name: "index_master_content_tags_on_current_migration_id",
              where: "current_migration_id IS NOT NULL",
              algorithm: :concurrently
    add_index :assignments, :group_category_id, where: "group_category_id IS NOT NULL", algorithm: :concurrently
    add_index :discussion_topics, :group_category_id, where: "group_category_id IS NOT NULL", algorithm: :concurrently
  end
end
