CanvasStatsd::DefaultTracking.track_sql
CanvasStatsd::DefaultTracking.track_active_record
CanvasStatsd::DefaultTracking.track_cache
CanvasStatsd::BlockTracking.logger = CanvasStatsd::RequestLogger.new(Rails.logger)
CanvasStatsd::RequestTracking.enable logger: Rails.logger
