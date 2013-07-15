class ChangeEventStreamFailuresExceptionToText < ActiveRecord::Migration
  tag :predeploy

  def self.up
    change_column :event_stream_failures, :exception, :text
  end

  def self.down
    change_column :event_stream_failures, :exception, :string
  end
end
