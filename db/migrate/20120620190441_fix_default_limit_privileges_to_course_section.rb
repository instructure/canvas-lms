class FixDefaultLimitPrivilegesToCourseSection < ActiveRecord::Migration
  tag :predeploy, :postdeploy
  self.transactional = false

  def self.up
    Enrollment.find_ids_in_ranges do |(start_id, end_id)|
      Enrollment.update_all({ :limit_privileges_to_course_section => false }, ["type IN ('StudentEnrollment', 'ObserverEnrollment', 'StudentViewEnrollment', 'DesignerEnrollment') AND id>=? AND id <=?", start_id, end_id])
      Enrollment.update_all({ :limit_privileges_to_course_section => false }, ["type IN ('TeacherEnrollment', 'TaEnrollment') AND limit_privileges_to_course_section IS NULL AND id>=? AND id <=?", start_id, end_id])
    end
  end

  def self.down
  end
end
