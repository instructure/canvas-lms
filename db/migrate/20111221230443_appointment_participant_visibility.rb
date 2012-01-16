class AppointmentParticipantVisibility < ActiveRecord::Migration
  def self.up
    add_column :appointment_groups, :participant_visibility, :string
  end

  def self.down
    remove_column :appointment_groups, :participant_visibility
  end
end
