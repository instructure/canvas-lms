class AppointmentParticipantVisibility < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :appointment_groups, :participant_visibility, :string
  end

  def self.down
    remove_column :appointment_groups, :participant_visibility
  end
end
