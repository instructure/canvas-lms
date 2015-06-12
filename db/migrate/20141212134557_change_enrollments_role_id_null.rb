class ChangeEnrollmentsRoleIdNull < ActiveRecord::Migration
  disable_ddl_transaction!
  tag :postdeploy

  def up
    cleanup_enrollments(Role.get_built_in_role("ObserverEnrollment"), "ObserverEnrollment")
    cleanup_enrollments(Role.get_built_in_role("StudentEnrollment"), "StudentViewEnrollment")
    change_column_null_with_less_locking :enrollments, :role_id
  end

  def cleanup_enrollments(role, type)
    Enrollment.find_ids_in_ranges(batch_size: 10000) do |start_id, end_id|
      Enrollment.where(<<-SQL, start_id, end_id, type, role.id).update_all(:role_id => role.id)
        (id BETWEEN ? AND ?) AND role_id IS NULL AND type=? AND NOT EXISTS
        (SELECT 1 FROM enrollments AS e2 WHERE
          e2.role_id=? AND
          e2.user_id=enrollments.user_id AND
          e2.type=enrollments.type AND
          e2.course_section_id=enrollments.course_section_id AND
          (e2.associated_user_id=enrollments.associated_user_id OR
            (e2.associated_user_id IS NULL AND enrollments.associated_user_id IS NULL)
          ))
      SQL
    end

    # delete remaining duplicate enrollments
    Enrollment.find_ids_in_ranges(batch_size: 10000) do |start_id, end_id|
      Enrollment.where(id: start_id..end_id, type: type, role_id: nil).delete_all
    end
  end

  def down
    change_column_null :enrollments, :role_id, true
  end
end
