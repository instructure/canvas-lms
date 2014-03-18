class AddForeignKeys16 < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_foreign_key_if_not_exists :pseudonyms, :sis_batches, delay_validation: true
    add_foreign_key_if_not_exists :accounts, :sis_batches, delay_validation: true
    add_foreign_key_if_not_exists :enrollment_terms, :sis_batches, delay_validation: true
    add_foreign_key_if_not_exists :abstract_courses, :sis_batches, delay_validation: true
    add_foreign_key_if_not_exists :courses, :sis_batches, delay_validation: true
    add_foreign_key_if_not_exists :course_sections, :sis_batches, delay_validation: true
    add_foreign_key_if_not_exists :enrollments, :sis_batches, delay_validation: true
    add_foreign_key_if_not_exists :groups, :sis_batches, delay_validation: true
    add_foreign_key_if_not_exists :group_memberships, :sis_batches, delay_validation: true
  end

  def self.down
    remove_foreign_key_if_exists :pseudonyms, :sis_batches
    remove_foreign_key_if_exists :accounts, :sis_batches
    remove_foreign_key_if_exists :enrollment_terms, :sis_batches
    remove_foreign_key_if_exists :abstract_courses, :sis_batches
    remove_foreign_key_if_exists :courses, :sis_batches
    remove_foreign_key_if_exists :course_sections, :sis_batches
    remove_foreign_key_if_exists :enrollments, :sis_batches
    remove_foreign_key_if_exists :groups, :sis_batches
    remove_foreign_key_if_exists :group_memberships, :sis_batches
  end
end
