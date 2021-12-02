# frozen_string_literal: true

class AddCourseIdToSubmissions < ActiveRecord::Migration[5.2]
  tag :predeploy
  disable_ddl_transaction!

  def change
    fk = connection.send(:foreign_key_name, "submissions", :column => "course_id")
    execute("ALTER TABLE #{Submission.quoted_table_name} ADD COLUMN course_id bigint CONSTRAINT #{fk} REFERENCES #{Course.quoted_table_name}(id)")
    add_index :submissions, :course_id, algorithm: :concurrently
  end
end
