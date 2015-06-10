# In rails4, this is always true, and in rails5, this setter is removed.
# In other words, just remove this whole block of code when we drop rails3 support.
if CANVAS_RAILS3
  ActiveSupport::Cache::Store.instrument = true
  if defined?(PhusionPassenger)
    # For whatever reason this is a thread-local setting, so under Passenger we
    # need to set it on each handler thread. Note that even in process mode,
    # Passenger spins up a separate thread in each process for the actual rack
    # handler.
    PhusionPassenger.on_event(:starting_request_handler_thread) do
      ActiveSupport::Cache::Store.instrument = true
    end
  end
end

%w[read write delete exist? generate].each do |method|
  ActiveSupport::Notifications.subscribe("cache_#{method}.active_support") do |_name, start, finish, _id, options|
    key = options[:key]
    elapsed_time = finish - start
    Rails.logger.debug("CacheStore: #{method} #{key.inspect} #{"%.4f" % elapsed_time}")
  end
end
