class DropOldSisStickyColumns < ActiveRecord::Migration
  def self.up
    remove_column :abstract_courses, :sis_name
    remove_column :abstract_courses, :sis_course_code
    remove_column :accounts, :sis_name
    remove_column :course_sections, :sis_name
    remove_column :courses, :sis_name
    remove_column :courses, :sis_course_code
    remove_column :enrollment_terms, :sis_name
    remove_column :groups, :sis_name
    remove_column :users, :sis_name
  end

  def self.down
    add_column :users, :sis_name, :string
    add_column :groups, :sis_name, :string
    add_column :enrollment_terms, :sis_name, :string
    add_column :courses, :sis_name, :string
    add_column :courses, :sis_course_code, :string
    add_column :course_sections, :sis_name, :string
    add_column :accounts, :sis_name, :string
    add_column :abstract_courses, :sis_name, :string
  end
end
