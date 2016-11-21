class AppointmentGroups < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :appointment_groups do |t|
      t.string :title
      t.text :description
      t.string   "location_name"
      t.string   "location_address"
      t.integer :context_id, :limit => 8
      t.string :context_type
      t.string :context_code
      t.integer :sub_context_id, :limit => 8
      t.string :sub_context_type
      t.string :sub_context_code
      t.string :workflow_state
      t.datetime :created_at
      t.datetime :updated_at
      t.datetime :start_at
      t.datetime :end_at
      t.integer :participants_per_appointment
      t.integer :max_appointments_per_participant # nil means no limit
      t.integer :min_appointments_per_participant, :default => 0
    end
    add_index :appointment_groups, [:context_id]
    add_index :appointment_groups, [:context_code]

    add_column :calendar_events, :parent_calendar_event_id, :integer, :limit => 8
    add_index :calendar_events, [:parent_calendar_event_id]
    add_column :calendar_events, :effective_context_code, :string
  end

  def self.down
    drop_table :appointment_groups

    remove_column :calendar_events, :parent_calendar_event_id
    remove_column :calendar_events, :effective_context_code
  end
end
