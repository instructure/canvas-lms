class MakeEnrolllmentStateLockNotNull < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    change_column_default(:enrollment_states, :lock_version, 0)
    EnrollmentState.find_ids_in_ranges(:batch_size => 100_000) do |min_id, max_id|
      EnrollmentState.where(:enrollment_id => min_id..max_id, :lock_version => nil).update_all(:lock_version => 0)
    end
    change_column_null_with_less_locking(:enrollment_states, :lock_version)
  end

  def down
  end
end
