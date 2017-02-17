class FixInvalidCourseIdsForEnrollments < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    Enrollment.reset_column_information
    DataFixup::FixInvalidCourseIdsOnEnrollments.send_later_if_production(:run)
  end

  def self.down
  end
end
