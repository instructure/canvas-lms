class FixBlankCourseSectionNames < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    DataFixup::FixBlankCourseSectionNames.run
    change_column_null_with_less_locking :course_sections, :name
  end

  def self.down
    change_column :course_sections, :name, :string, null: true
  end
end
