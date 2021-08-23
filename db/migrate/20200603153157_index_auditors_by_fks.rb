# frozen_string_literal: true

class IndexAuditorsByFks < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!
  tag :postdeploy

  def up
    add_index :auditor_grade_change_records, :account_id, algorithm: :concurrently, if_not_exists: true
    add_index :auditor_grade_change_records, :submission_id, algorithm: :concurrently, if_not_exists: true
    add_index :auditor_grade_change_records, :student_id, algorithm: :concurrently, if_not_exists: true
    add_index :auditor_grade_change_records, :grader_id, algorithm: :concurrently, if_not_exists: true
    add_index :auditor_course_records, :sis_batch_id, algorithm: :concurrently, if_not_exists: true
    add_index :auditor_course_records, :user_id, algorithm: :concurrently, if_not_exists: true
  end

  def down
    remove_index :auditor_grade_change_records, column: :account_id, algorithm: :concurrently, if_exists: true
    remove_index :auditor_grade_change_records, column: :submission_id, algorithm: :concurrently, if_exists: true
    remove_index :auditor_grade_change_records, column: :student_id, algorithm: :concurrently, if_exists: true
    remove_index :auditor_grade_change_records, column: :grader_id, algorithm: :concurrently, if_exists: true
    remove_index :auditor_course_records, column: :sis_batch_id, algorithm: :concurrently, if_exists: true
    remove_index :auditor_course_records, column: :user_id, algorithm: :concurrently, if_exists: true
  end
end
