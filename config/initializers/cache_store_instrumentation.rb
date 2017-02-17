ActiveSupport::Notifications.subscribe("cache_generate.active_support") do |_name, start, finish, _id, _options|
  elapsed_time = finish - start
  # used by Redis::Client#log_request_response added in lib/canvas/redis.rb
  Thread.current[:last_cache_generate] = elapsed_time
end
