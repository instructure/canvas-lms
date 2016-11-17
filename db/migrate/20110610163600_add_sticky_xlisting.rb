class AddStickyXlisting < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :course_sections, :sticky_xlist, :boolean
  end

  def self.down
    remove_column :course_sections, :sticky_xlist
  end
end
