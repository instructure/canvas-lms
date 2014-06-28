class FixInvalidCourseIdsForEnrollments < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    DataFixup::FixInvalidCourseIdsOnEnrollments.send_later_if_production(:run)
  end

  def self.down
  end
end
