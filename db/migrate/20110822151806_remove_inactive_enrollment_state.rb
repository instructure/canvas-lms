class RemoveInactiveEnrollmentState < ActiveRecord::Migration
  def self.up
    Delayed::Backend::ActiveRecord::Job.delete_all(:tag => 'EnrollmentDateRestrictions.update_restricted_enrollments')
    Enrollment.update_all({:workflow_state => 'active'}, :workflow_state => 'inactive')
  end

  def self.down
  end
end
