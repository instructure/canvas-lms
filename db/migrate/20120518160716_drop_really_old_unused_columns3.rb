class DropReallyOldUnusedColumns3 < ActiveRecord::Migration
  tag :postdeploy

  self.transactional = false

  # cleanup for some legacy database schema that may not even exist for databases created post-OSS release
  def self.maybe_drop(table, column)
    begin
      remove_column(table, column)
    rescue
      # exception is db-dependent
    end
  end

  def self.up
   maybe_drop :calendar_events, :calendar_event_repeat_id
   maybe_drop :calendar_events, :for_repeat_on
  end

  def self.down
  end
end
