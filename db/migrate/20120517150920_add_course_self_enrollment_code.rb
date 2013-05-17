class AddCourseSelfEnrollmentCode < ActiveRecord::Migration
  self.transactional = false
  tag :predeploy

  def self.up
    add_column :courses, :self_enrollment_code, :string
    add_index :courses, [:self_enrollment_code], :unique => true, :concurrently => true, :conditions => "self_enrollment_code IS NOT NULL"
  end

  def self.down
    remove_column :courses, :self_enrollment_code
  end
end
