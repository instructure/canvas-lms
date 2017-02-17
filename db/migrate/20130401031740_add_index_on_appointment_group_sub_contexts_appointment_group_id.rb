class AddIndexOnAppointmentGroupSubContextsAppointmentGroupId < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    add_index :appointment_group_sub_contexts, :appointment_group_id, :algorithm => :concurrently
  end

  def self.down
    remove_index :appointment_group_sub_contexts, :column => :appointment_group_id
  end
end
