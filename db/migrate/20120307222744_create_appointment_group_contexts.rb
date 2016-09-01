class CreateAppointmentGroupContexts < ActiveRecord::Migration
  tag :predeploy

  def self.up
    create_table :appointment_group_contexts do |t|
      t.references :appointment_group, :limit => 8
      t.string :context_code
      t.integer :context_id, :limit => 8
      t.string :context_type
      t.timestamps null: true
    end
  end

  def self.down
    drop_table :appointment_group_contexts
  end
end
