class IndexCalendarEventsEffectiveContextCode < ActiveRecord::Migration
  def self.up
    if connection.adapter_name == 'PostgreSQL'
      connection.execute("CREATE INDEX index_calendar_events_on_effective_context_code ON calendar_events(effective_context_code) WHERE effective_context_code IS NOT NULL")
    else
      add_index :calendar_events, [:effective_context_code]
    end
  end

  def self.down
    remove_index :calendar_events, [:effective_context_code]
  end
end
