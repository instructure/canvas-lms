class EnrollmentsOnRootAccountAndCourse < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_index :enrollments, [:root_account_id, :course_id],
              algorithm: :concurrently
  end

  def self.down
    remove_index :enrollments, [:root_account_id, :course_id]
  end
end
