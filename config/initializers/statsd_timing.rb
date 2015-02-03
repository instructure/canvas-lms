sql_counter = CanvasStatsd::Counter.new('sql_counter', ['SCHEMA'])

ActiveSupport::Notifications.subscribe(/process_action.action_controller/) do |*args|
  request_stat = CanvasStatsd::RequestStat.new(*args)
  request_stat.sql_count = sql_counter.finalize_count
  request_stat.report
end

ActiveSupport::Notifications.subscribe(/start_processing.action_controller/) do |*args|
  sql_counter.start
end

ActiveSupport::Notifications.subscribe(/sql.active_record/) do |name, start, finish, id, payload|
  sql_counter.track payload.fetch(:name)
end
