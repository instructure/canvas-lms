class AddLockVersionToEnrollmentStates < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :enrollment_states, :lock_version, :integer
  end
end
