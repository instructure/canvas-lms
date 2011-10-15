class GroupCategoriesMigration < ActiveRecord::Migration
  def self.up
    create_table :group_categories do |group_categories|
      group_categories.column :context_id, :integer, :limit => 8
      group_categories.column :context_type, :string
      group_categories.column :name, :string
      group_categories.column :role, :string
      group_categories.column :deleted_at, :datetime
    end

    add_column :groups, :group_category_id, :integer, :limit => 8
    add_column :assignments, :group_category_id, :integer, :limit => 8
  end

  def self.down
    remove_column :groups, :group_category_id
    remove_column :assignments, :group_category_id
    drop_table :group_categories
  end
end
