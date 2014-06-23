ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Migration.verbose = false
ActiveRecord::Schema.define(version: 1) do
  create_table :event_stream_failures, force: true do |t|
    t.string "operation"
    t.string "event_stream"
    t.string "record_id"
    t.text "payload"
    t.text "exception"
    t.text "backtrace"
  end
end
