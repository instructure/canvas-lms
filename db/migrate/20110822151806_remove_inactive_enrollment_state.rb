class RemoveInactiveEnrollmentState < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    Delayed::Backend::ActiveRecord::Job.delete_all(:tag => 'EnrollmentDateRestrictions.update_restricted_enrollments')
    Enrollment.where(:workflow_state => 'inactive').update_all(:workflow_state => 'active')
  end

  def self.down
  end
end
