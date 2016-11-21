class AddEnrollmentSisStickiness < ActiveRecord::Migration[4.2]
  tag :predeploy


  def self.up
    add_column :enrollments, :stuck_sis_fields, :text
  end

  def self.down
    drop_column :enrollments, :stuck_sis_fields
  end

end
