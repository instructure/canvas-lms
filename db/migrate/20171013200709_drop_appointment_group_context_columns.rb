class DropAppointmentGroupContextColumns < ActiveRecord::Migration[5.0]
  tag :postdeploy

  def change
    remove_column :appointment_groups, :context_id
    remove_column :appointment_groups, :context_type
    remove_column :appointment_groups, :sub_context_id
    remove_column :appointment_groups, :sub_context_type
  end
end
