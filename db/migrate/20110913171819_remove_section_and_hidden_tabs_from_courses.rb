class RemoveSectionAndHiddenTabsFromCourses < ActiveRecord::Migration
  def self.up
    remove_column :courses, :section
    remove_column :courses, :hidden_tabs
  end

  def self.down
    add_column :courses, :section, :string
    add_column :courses, :hidden_tabs, :text
  end
end
