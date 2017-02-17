class ConstrainAssignmentGroupCategoryIds < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    Assignment.where(:group_category_id => 0).update_all(:group_category_id => nil)
    add_foreign_key :assignments, :group_categories
  end

  def self.down
    remove_foreign_key :assignments, :group_categories
  end
end
