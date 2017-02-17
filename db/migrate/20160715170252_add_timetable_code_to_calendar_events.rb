class AddTimetableCodeToCalendarEvents < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :calendar_events, :timetable_code, :string
    add_index :calendar_events, [:context_id, :context_type, :timetable_code], where: "timetable_code IS NOT NULL",
      unique: true, algorithm: :concurrently, name: "index_calendar_events_on_context_and_timetable_code"
  end
end
