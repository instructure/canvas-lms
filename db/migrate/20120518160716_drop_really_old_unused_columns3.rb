class DropReallyOldUnusedColumns3 < ActiveRecord::Migration[4.2]
  tag :postdeploy

  disable_ddl_transaction!

  # cleanup for some legacy database schema that may not even exist for databases created post-OSS release
  def self.maybe_drop(table, column)
    remove_column(table, column) if self.connection.columns(table).map(&:name).include?(column.to_s)
  end

  def self.up
   maybe_drop :calendar_events, :calendar_event_repeat_id
   maybe_drop :calendar_events, :for_repeat_on
  end

  def self.down
  end
end
