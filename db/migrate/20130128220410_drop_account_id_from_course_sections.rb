class DropAccountIdFromCourseSections < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    remove_column :course_sections, :account_id
  end

  def self.down
    add_column :course_sections, :account_id, :integer, :limit => 8
  end
end
