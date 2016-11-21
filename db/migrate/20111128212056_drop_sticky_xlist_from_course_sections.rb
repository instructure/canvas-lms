class DropStickyXlistFromCourseSections < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    remove_column :course_sections, :sticky_xlist
  end

  def self.down
    add_column :course_sections, :sticky_xlist, :boolean
  end
end
