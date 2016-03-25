class AddGcalToCalendarEvent < ActiveRecord::Migration
  tag :predeploy
  def change
    add_column :calendar_events, :google_calendar_id, :string
  end
end
