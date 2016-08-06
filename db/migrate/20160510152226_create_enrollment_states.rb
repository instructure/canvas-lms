class CreateEnrollmentStates < ActiveRecord::Migration
  tag :predeploy

  def up
    create_table :enrollment_states, :id => false do |t|
      t.integer :enrollment_id, limit: 8, null: false

      t.string :state
      t.boolean :state_is_current, null: false, default: false
      t.datetime :state_started_at
      t.datetime :state_valid_until

      t.boolean :restricted_access, null: false, default: false
      t.boolean :access_is_current, null: false, default: false

      # these will go away - for initial diagnostic purposes
      t.datetime :state_invalidated_at
      t.datetime :state_recalculated_at
      t.datetime :access_invalidated_at
      t.datetime :access_recalculated_at
    end

    add_index :enrollment_states, :enrollment_id, :unique => true, :name => "index_enrollment_states"
    execute("ALTER TABLE #{EnrollmentState.quoted_table_name} ADD CONSTRAINT enrollment_states_pkey PRIMARY KEY USING INDEX index_enrollment_states")

    add_index :enrollment_states, :state
    add_index :enrollment_states, [:state_is_current, :access_is_current], :name => "index_enrollment_states_on_currents"
    add_index :enrollment_states, :state_valid_until

    add_foreign_key :enrollment_states, :enrollments
  end

  def down
    drop_table :enrollment_states
  end
end
