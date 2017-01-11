module ConsulInitializer
  def self.configure_with(settings_hash, logger=Rails.logger)
    if settings_hash.present?
      begin
        Canvas::DynamicSettings.config = settings_hash
      rescue Imperium::UnableToConnectError
        logger.warn("INITIALIZATION: can't reach consul, attempts to load DynamicSettings will fail")
      end
    end
  end

  def self.fallback_to(settings_hash)
    if settings_hash.present?
      Canvas::DynamicSettings.fallback_data = settings_hash.with_indifferent_access
    end
  end

end

Rails.configuration.to_prepare do
  settings = ConfigFile.load("consul")
  ConsulInitializer.configure_with(settings)
  fallback_settings = ConfigFile.load("dynamic_settings")
  ConsulInitializer.fallback_to(fallback_settings)
end

Canvas::Reloader.on_reload do
  Canvas::DynamicSettings.reset_cache!
end
