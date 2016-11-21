class AddSelfEnrollmentLimit < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :courses, :self_enrollment_limit, :integer
  end

  def self.down
    remove_column :courses, :self_enrollment_limit
  end
end
