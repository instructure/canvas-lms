class CreateAppointmentGroupSubContexts < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :appointment_group_sub_contexts do |t|
      t.references :appointment_group, :limit => 8
      t.integer :sub_context_id, :limit => 8
      t.string :sub_context_type
      t.string :sub_context_code
      t.timestamps null: true
    end

    add_index :appointment_group_sub_contexts, :id

    AppointmentGroup.all.each do |ag|
      next unless ag.sub_context_id
      sc = ag.appointment_group_sub_contexts.build
      sc.sub_context_id   = ag.sub_context_id
      sc.sub_context_type = ag.sub_context_type
      sc.sub_context_code = ag.sub_context_code
      sc.save!
    end
  end

  def self.down
    drop_table :appointment_group_sub_contexts
  end
end
