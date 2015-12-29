module ConsulInitializer
  def self.configure_with(settings_hash, logger=Rails.logger)
    if settings_hash.present?
      begin
        Canvas::DynamicSettings.config = settings_hash
      rescue Faraday::ConnectionFailed
        logger.warn(initialization_failed_message("can't reach consul"))
      end
    else
      logger.warn(initialization_failed_message("No consul configuration"))
    end
  end

  def self.initialization_failed_message(reason)
    "INITIALIZATION: #{reason}, attempts to load DynamicSettings will fail"
  end
end

Rails.configuration.to_prepare do
  settings = ConfigFile.load("consul")
  ConsulInitializer.configure_with(settings)
end
