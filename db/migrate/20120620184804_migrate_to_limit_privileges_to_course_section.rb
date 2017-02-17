class MigrateToLimitPrivilegesToCourseSection < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    Enrollment.find_ids_in_ranges do |(start_id, end_id)|
      Enrollment.where(["limit_privileges_to_course_section IS NULL AND id>=? AND id<=?", start_id, end_id]).update_all('limit_privileges_to_course_section=limit_priveleges_to_course_section')
    end
  end

  def self.down
  end
end
