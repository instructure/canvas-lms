class AddForeignKeyIndexes2 < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_index :content_exports, :content_migration_id, algorithm: :concurrently
    add_index :abstract_courses, :sis_batch_id, where: "sis_batch_id IS NOT NULL", algorithm: :concurrently
    add_index :accounts, :sis_batch_id, where: "sis_batch_id IS NOT NULL", algorithm: :concurrently
    add_index :courses, :sis_batch_id, where: "sis_batch_id IS NOT NULL", algorithm: :concurrently
    add_index :course_sections, :sis_batch_id, where: "sis_batch_id IS NOT NULL", algorithm: :concurrently
    add_index :enrollments, :sis_batch_id, where: "sis_batch_id IS NOT NULL", algorithm: :concurrently
    add_index :groups, :sis_batch_id, where: "sis_batch_id IS NOT NULL", algorithm: :concurrently
    add_index :group_memberships, :sis_batch_id, where: "sis_batch_id IS NOT NULL", algorithm: :concurrently
    add_index :pseudonyms, :sis_batch_id, where: "sis_batch_id IS NOT NULL", algorithm: :concurrently
    add_index :course_account_associations, :course_section_id, algorithm: :concurrently
    add_index :content_migrations, :source_course_id, where: "source_course_id IS NOT NULL", algorithm: :concurrently
    add_index :custom_gradebook_columns, :course_id, algorithm: :concurrently
    add_index :courses, :abstract_course_id, where: "abstract_course_id IS NOT NULL", algorithm: :concurrently
    add_index :abstract_courses, :enrollment_term_id, algorithm: :concurrently
    add_index :course_sections, :enrollment_term_id, algorithm: :concurrently
    add_index :enrollment_dates_overrides, :enrollment_term_id, algorithm: :concurrently
    add_index :sis_batches, :batch_mode_term_id, where: "batch_mode_term_id IS NOT NULL", algorithm: :concurrently
    add_index :submissions, :group_id, where: "group_id IS NOT NULL", algorithm: :concurrently
  end

  def self.down
    remove_index :content_exports, :content_migration_id
    remove_index :abstract_courses, :sis_batch_id
    remove_index :accounts, :sis_batch_id
    remove_index :courses, :sis_batch_id
    remove_index :course_sections, :sis_batch_id
    remove_index :enrollments, :sis_batch_id
    remove_index :groups, :sis_batch_id
    remove_index :group_memberships, :sis_batch_id
    remove_index :pseudonyms, :sis_batch_id
    remove_index :course_account_associations, :course_section_id
    remove_index :content_migrations, :source_course_id
    remove_index :custom_gradebook_columns, :course_id
    remove_index :courses, :abstract_course_id
    remove_index :abstract_courses, :enrollment_term_id
    remove_index :course_sections, :enrollment_term_id
    remove_index :enrollment_dates_overrides, :enrollment_term_id
    remove_index :sis_batches, :batch_mode_term_id
    remove_index :submissions, :group_id
  end
end
