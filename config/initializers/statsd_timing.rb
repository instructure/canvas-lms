Aroi::Instrumentation.instrument_creation!

ar_counter = CanvasStatsd::Counter.new('ar_counter')
sql_tracker = SqlMetrics::Tracker.new(blocked_names: ['SCHEMA'])

ActiveSupport::Notifications.subscribe(/start_processing.action_controller/) do |*args|
  sql_tracker.start
  ar_counter.start
end

ActiveSupport::Notifications.subscribe(/sql.active_record/) do |name, start, finish, id, payload|
  sql_tracker.track payload.fetch(:name), payload.fetch(:sql)
end

ActiveSupport::Notifications.subscribe(/instance.active_record/) do |name, start, finish, id, payload|
  ar_counter.track payload.fetch(:name, '')
end

ActiveSupport::Notifications.subscribe(/process_action.action_controller/) do |*args|
  request_stat = CanvasStatsd::RequestStat.new(*args)
  request_stat.ar_count = ar_counter.finalize_count
  request_stat.sql_read_count = sql_tracker.num_reads
  request_stat.sql_write_count = sql_tracker.num_writes
  request_stat.sql_cache_count = sql_tracker.num_caches
  request_stat.report
end
