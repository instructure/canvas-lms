class AddTableEventStreamFailures < ActiveRecord::Migration
  tag :predeploy

  def self.up
    create_table :event_stream_failures do |t|
      t.string :operation, :null => false
      t.string :event_stream, :null => false
      t.string :record_id, :null => false
      t.text :payload, :null => false
      t.string :exception
      t.text :backtrace
      t.timestamps null: true
    end
  end

  def self.down
    drop_table :event_stream_failures
  end
end
