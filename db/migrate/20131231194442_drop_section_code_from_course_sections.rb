class DropSectionCodeFromCourseSections < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    remove_column :course_sections, :section_code
  end

  def self.down
    add_column :course_sections, :section_code, :string
  end
end
