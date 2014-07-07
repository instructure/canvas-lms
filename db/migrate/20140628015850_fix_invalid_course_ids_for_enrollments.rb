class FixInvalidCourseIdsForEnrollments < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    Enrollment.reset_column_information if !Rails.env.production?
    DataFixup::FixInvalidCourseIdsOnEnrollments.send_later_if_production(:run)
  end

  def self.down
  end
end
