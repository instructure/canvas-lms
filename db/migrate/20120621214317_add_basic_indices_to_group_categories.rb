class AddBasicIndicesToGroupCategories < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    add_index :group_categories, [:context_id, :context_type], :name => "index_group_categories_on_context"
    add_index :group_categories, :role, :name => "index_group_categories_on_role"
  end

  def self.down
    remove_index :group_categories, :name => "index_group_categories_on_context"
    remove_index :group_categories, :name => "index_group_categories_on_role"
  end
end
