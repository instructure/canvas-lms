class ChangeCalendarEventsLocationToText < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    change_column :calendar_events, :location_name, :text
    change_column :calendar_events, :location_address, :text
  end

  def down
    change_column :calendar_events, :location_name, :string
    change_column :calendar_events, :location_address, :string
  end
end
