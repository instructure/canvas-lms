class FixBlankCourseSectionNames < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    DataFixup::FixBlankCourseSectionNames.run
    change_column_null :course_sections, :name, false
  end

  def self.down
    change_column :course_sections, :name, :string, null: true
  end
end
