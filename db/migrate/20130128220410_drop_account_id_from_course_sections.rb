class DropAccountIdFromCourseSections < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    remove_column :course_sections, :account_id
  end

  def self.down
    add_column :course_sections, :account_id, :integer, :limit => 8
  end
end
