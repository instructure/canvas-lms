class DropEnrollmentStateLogColumns < ActiveRecord::Migration
  tag :postdeploy

  def up
    remove_column :enrollment_states, :state_invalidated_at
    remove_column :enrollment_states, :state_recalculated_at
    remove_column :enrollment_states, :access_invalidated_at
    remove_column :enrollment_states, :access_recalculated_at
  end

  def down
    add_column :enrollment_states, :state_invalidated_at, :datetime
    add_column :enrollment_states, :state_recalculated_at, :datetime
    add_column :enrollment_states, :access_invalidated_at, :datetime
    add_column :enrollment_states, :access_recalculated_at, :datetime
  end
end
