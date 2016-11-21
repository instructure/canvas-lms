class ChangeEventStreamFailuresExceptionToText < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    change_column :event_stream_failures, :exception, :text
  end

  def self.down
    change_column :event_stream_failures, :exception, :string
  end
end
