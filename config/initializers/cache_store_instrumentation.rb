%w[read write delete exist? generate].each do |method|
  ActiveSupport::Notifications.subscribe("cache_#{method}.active_support") do |_name, start, finish, _id, options|
    key = options[:key]
    elapsed_time = finish - start
    Rails.logger.debug("CacheStore: #{method} #{key.inspect} #{"%.4f" % elapsed_time}")
  end
end
