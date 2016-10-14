class AddLockVersionToEnrollmentStates < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :enrollment_states, :lock_version, :integer
  end
end
