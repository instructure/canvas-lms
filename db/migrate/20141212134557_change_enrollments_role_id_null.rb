class ChangeEnrollmentsRoleIdNull < ActiveRecord::Migration
  disable_ddl_transaction!
  tag :postdeploy

  def up
    role = Role.get_built_in_role("ObserverEnrollment")
    while Enrollment.where("role_id IS NULL AND type = ?", role.name).limit(1000).update_all(:role_id => role.id) > 0; end
    change_column_null_with_less_locking :enrollments, :role_id
  end

  def down
    change_column_null :enrollments, :role_id, true
  end
end
