class GenericSisStickinessRefactorColumns < ActiveRecord::Migration

  def self.up
    add_column :abstract_courses, :stuck_sis_fields, :text
    add_column :accounts, :stuck_sis_fields, :text
    add_column :courses, :stuck_sis_fields, :text
    add_column :groups, :stuck_sis_fields, :text
    add_column :course_sections, :stuck_sis_fields, :text
    add_column :enrollment_terms, :stuck_sis_fields, :text
    add_column :users, :stuck_sis_fields, :text
  end

  def self.down
    drop_column :users, :stuck_sis_fields
    drop_column :enrollment_terms, :stuck_sis_fields
    drop_column :course_sections, :stuck_sis_fields
    drop_column :groups, :stuck_sis_fields
    drop_column :courses, :stuck_sis_fields
    drop_column :accounts, :stuck_sis_fields
    drop_column :abstract_courses, :stuck_sis_fields
  end

end
