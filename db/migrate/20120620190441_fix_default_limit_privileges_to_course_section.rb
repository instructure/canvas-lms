class FixDefaultLimitPrivilegesToCourseSection < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    Enrollment.find_ids_in_ranges do |(start_id, end_id)|
      Enrollment.where("type IN ('StudentEnrollment', 'ObserverEnrollment', 'StudentViewEnrollment', 'DesignerEnrollment') AND id>=? AND id <=?", start_id, end_id).update_all(:limit_privileges_to_course_section => false)
      Enrollment.where("type IN ('TeacherEnrollment', 'TaEnrollment') AND limit_privileges_to_course_section IS NULL AND id>=? AND id <=?", start_id, end_id).update_all(:limit_privileges_to_course_section => false)
    end
  end

  def self.down
  end
end
