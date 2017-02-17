class CreateChildContentTags < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    create_table :master_courses_child_content_tags do |t|
      t.integer :child_subscription_id, limit: 8, null: false # mainly for bulk loading on import

      t.string :content_type, null: false
      t.integer :content_id, limit: 8, null: false

      t.text :downstream_changes
    end

    add_index :master_courses_child_content_tags, [:content_type, :content_id], :unique => true,
      :name => "index_child_content_tags_on_content"

    add_foreign_key :master_courses_child_content_tags, :master_courses_child_subscriptions, column: "child_subscription_id"
    add_index :master_courses_child_content_tags, :child_subscription_id, :name => "index_child_content_tags_on_subscription"

    # may as well add these now too
    add_column :master_courses_master_templates, :default_restrictions, :text

    add_column :master_courses_master_content_tags, :restrictions, :text # my gut tells me that we might not leave this at settings/content
    add_column :master_courses_master_content_tags, :migration_id, :string
    add_index :master_courses_master_content_tags, :migration_id, :unique => true, :name => "index_master_content_tags_on_migration_id"
  end
end
