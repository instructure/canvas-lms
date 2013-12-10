class AddCourseSelfEnrollmentCode < ActiveRecord::Migration
  disable_ddl_transaction!
  tag :predeploy

  def self.up
    add_column :courses, :self_enrollment_code, :string
    add_index :courses, [:self_enrollment_code], :unique => true, :algorithm => :concurrently, :where => "self_enrollment_code IS NOT NULL"
  end

  def self.down
    remove_column :courses, :self_enrollment_code
  end
end
