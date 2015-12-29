module Services
  class RichContent
    def self.env_for(root_account)
      enabled = check_feature_flag(root_account)
      env_hash = { RICH_CONTENT_SERVICE_ENABLED: enabled }
      if enabled
        settings = Canvas::DynamicSettings.find("rich-content-service")
        env_hash[:RICH_CONTENT_APP_HOST] = settings["app-host"]
        env_hash[:RICH_CONTENT_CDN_HOST] = settings["cdn-host"]
      end
      env_hash
    end

    def self.check_feature_flag(root_account)
      return false unless root_account.present?
      root_account.feature_enabled?(:rich_content_service)
    end
  end
end
