class DropStickyXlistFromCourseSections < ActiveRecord::Migration
  def self.up
    remove_column :course_sections, :sticky_xlist
  end

  def self.down
    add_column :course_sections, :sticky_xlist, :boolean
  end
end
