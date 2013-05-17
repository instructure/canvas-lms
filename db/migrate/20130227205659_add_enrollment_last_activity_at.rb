class AddEnrollmentLastActivityAt < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :enrollments, :last_activity_at, :datetime
  end

  def self.down
    remove_column :enrollments, :last_activity_at
  end
end
