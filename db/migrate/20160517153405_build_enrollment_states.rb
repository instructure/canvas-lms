class BuildEnrollmentStates < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    EnrollmentState.build_states_in_ranges
  end

  def down
  end
end
