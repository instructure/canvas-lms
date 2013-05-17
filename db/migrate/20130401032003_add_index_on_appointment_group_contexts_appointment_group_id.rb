class AddIndexOnAppointmentGroupContextsAppointmentGroupId < ActiveRecord::Migration
  tag :predeploy
  self.transactional = false

  def self.up
    add_index :appointment_group_contexts, :appointment_group_id, :concurrently => true
  end

  def self.down
    remove_index :appointment_group_contexts, :column => :appointment_group_id
  end
end
