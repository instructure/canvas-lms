module ConsulInitializer
  def self.configure_with(settings_hash, logger=Rails.logger)
    if settings_hash.present?
      begin
        Canvas::DynamicSettings.config = settings_hash
      rescue Faraday::ConnectionFailed
        logger.warn("INITIALIZATION: can't reach consul, attempts to load DynamicSettings will fail")
      end
    end
  end

end

Rails.configuration.to_prepare do
  settings = ConfigFile.load("consul")
  ConsulInitializer.configure_with(settings)
end
