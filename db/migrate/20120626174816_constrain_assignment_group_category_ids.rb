class ConstrainAssignmentGroupCategoryIds < ActiveRecord::Migration
  tag :postdeploy
  self.transactional = false

  def self.up
    Assignment.update_all({:group_category_id => nil}, <<-SQL)
      NOT EXISTS (
        SELECT group_categories.id FROM group_categories
        WHERE group_categories.id=assignments.group_category_id)
    SQL
    add_foreign_key :assignments, :group_categories, :delay_validation => true
  end

  def self.down
    remove_foreign_key :assignments, :group_categories
  end
end
