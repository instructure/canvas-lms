class AddParticipantsPerAppointmentToCalendarEvents < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    change_table :calendar_events do |t|
      t.integer :participants_per_appointment
      t.boolean :override_participants_per_appointment
    end
  end

  def self.down
    change_table :calendar_events do |t|
      t.remove :participants_per_appointment
      t.remove :override_participants_per_appointment
    end
  end
end
