if CANVAS_RAILS3
  # In rails4, this is always true, and in rails5, this setter is removed
  ActiveSupport::Cache::Store.instrument = true
end

%w[read write delete exist? generate].each do |method|
  ActiveSupport::Notifications.subscribe("cache_#{method}.active_support") do |_name, start, finish, _id, options|
    key = options[:key]
    elapsed_time = finish - start
    Rails.logger.debug("CacheStore: #{method} #{key.inspect} #{"%.4f" % elapsed_time}")
  end
end
