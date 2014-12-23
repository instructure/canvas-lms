class ChangeEnrollmentsRoleIdNull < ActiveRecord::Migration
  disable_ddl_transaction!
  tag :postdeploy

  def up
    cleanup_observer_enrollments
    cleanup_student_view_enrollments
    change_column_null_with_less_locking :enrollments, :role_id
  end

  def cleanup_observer_enrollments
    role = Role.get_built_in_role("ObserverEnrollment")
    Enrollment.find_ids_in_ranges(batch_size: 10000) do |start_id, end_id|
      Enrollment.where(id: start_id..end_id, role_id: nil, type: role.name).update_all(:role_id => role.id)
    end
  end

  def cleanup_student_view_enrollments
    student_role = Role.get_built_in_role("StudentEnrollment")
    # set the proper role_id where this has not already happened manually
    Enrollment.find_ids_in_ranges(batch_size: 10000) do |start_id, end_id|
      Enrollment.where(<<-SQL, start_id, end_id, student_role.id).update_all(:role_id => student_role.id)
        (id BETWEEN ? AND ?) AND role_id IS NULL AND type='StudentViewEnrollment' AND NOT EXISTS
        (SELECT 1 FROM enrollments AS e2 WHERE e2.user_id=enrollments.user_id AND
          e2.type='StudentViewEnrollment' AND e2.role_id=? AND
          e2.course_section_id=enrollments.course_section_id AND
          e2.associated_user_id IS NULL)
      SQL
    end
    # delete remaining (obsolete) StudentViewEnrollments with no role_id
    Enrollment.find_ids_in_ranges(batch_size: 10000) do |start_id, end_id|
      Enrollment.where(id: start_id..end_id, type: 'StudentViewEnrollment', role_id: nil).delete_all
    end
  end

  def down
    change_column_null :enrollments, :role_id, true
  end
end
