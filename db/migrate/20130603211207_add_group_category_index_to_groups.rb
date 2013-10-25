class AddGroupCategoryIndexToGroups < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_index :groups, :group_category_id, :concurrently => true
  end

  def self.down
    remove_index :groups, :group_category_id
  end
end
