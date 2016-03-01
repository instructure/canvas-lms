module Services
  class RichContent

    def self.env_for(root_account, risk_level: :highrisk)
      enabled = check_feature_flag(root_account, :rich_content_service)
      env_hash = { RICH_CONTENT_SERVICE_ENABLED: enabled }
      if enabled
        env_hash = env_hash.merge(fine_grained_flags(root_account, risk_level))
        env_hash = env_hash.merge(service_settings)
      end
      env_hash
    end

    class << self
      private
      def check_feature_flag(root_account, flag)
        return false unless root_account.present?
        root_account.feature_enabled?(flag) || false # ensure true boolean
      end

      def service_settings
        settings = Canvas::DynamicSettings.from_cache("rich-content-service", expires_in: 5.minutes)
        {
          RICH_CONTENT_APP_HOST: settings["app-host"],
          RICH_CONTENT_CDN_HOST: settings["cdn-host"]
        }
      rescue Faraday::ConnectionFailed,
             Faraday::ClientError,
             Canvas::DynamicSettings::ConsulError => e
        Canvas::Errors.capture_exception(:rce_flag, e)
        {
          RICH_CONTENT_APP_HOST: "error",
          RICH_CONTENT_CDN_HOST: "error"
        }
      end

      def fine_grained_flags(root_account, risk_level)
        medium_risk_flag = check_feature_flag(root_account, :rich_content_service_with_sidebar)
        high_risk_flag = check_feature_flag(root_account, :rich_content_service_high_risk)
        contextually_on = (
          risk_level == :basic ||
          (risk_level == :sidebar && medium_risk_flag) ||
          high_risk_flag
        )
        {
          RICH_CONTENT_SIDEBAR_ENABLED: medium_risk_flag,
          RICH_CONTENT_HIGH_RISK_ENABLED: high_risk_flag,
          RICH_CONTENT_SERVICE_CONTEXTUALLY_ENABLED: contextually_on
        }
      end
    end
  end
end
