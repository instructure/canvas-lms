class DropCalendarEventContexts < ActiveRecord::Migration[5.0]
  tag :postdeploy

  def up
    drop_table :calendar_event_contexts if connection.table_exists?(:calendar_event_contexts)
  end
end
