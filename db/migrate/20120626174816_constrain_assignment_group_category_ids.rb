class ConstrainAssignmentGroupCategoryIds < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    Assignment.update_all({:group_category_id => nil}, :group_category_id => 0)
    add_foreign_key :assignments, :group_categories
  end

  def self.down
    remove_foreign_key :assignments, :group_categories
  end
end
