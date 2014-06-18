class AddTotalActivityTimeToEnrollment < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :enrollments, :total_activity_time, :integer
  end

  def self.down
    remove_column :enrollments, :total_activity_time
  end
end
