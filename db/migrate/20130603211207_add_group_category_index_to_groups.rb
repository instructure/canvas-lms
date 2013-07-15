class AddGroupCategoryIndexToGroups < ActiveRecord::Migration
  tag :postdeploy
  self.transactional = false

  def self.up
    add_index :groups, :group_category_id, :concurrently => true
  end

  def self.down
    remove_index :groups, :group_category_id
  end
end
