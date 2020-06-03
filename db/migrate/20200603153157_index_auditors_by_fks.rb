class IndexAuditorsByFks < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!
  tag :postdeploy

  def up
    add_index :auditor_grade_change_records, :account_id, algorithm: :concurrently
    add_index :auditor_grade_change_records, :submission_id, algorithm: :concurrently
    add_index :auditor_grade_change_records, :student_id, algorithm: :concurrently
    add_index :auditor_grade_change_records, :grader_id, algorithm: :concurrently
    add_index :auditor_course_records, :sis_batch_id, algorithm: :concurrently
    add_index :auditor_course_records, :user_id, algorithm: :concurrently
  end

  def down
    remove_index :auditor_grade_change_records, :account_id, algorithm: :concurrently
    remove_index :auditor_grade_change_records, :submission_id, algorithm: :concurrently
    remove_index :auditor_grade_change_records, :student_id, algorithm: :concurrently
    remove_index :auditor_grade_change_records, :grader_id, algorithm: :concurrently
    remove_index :auditor_course_records, :sis_batch_id, algorithm: :concurrently
    remove_index :auditor_course_records, :user_id, algorithm: :concurrently
  end
end
