module Services
  class RichContent
    def self.env_for(root_account, risk_level: :highrisk, user: nil, domain: nil)
      enabled = contextually_on(root_account, risk_level)
      env_hash = { RICH_CONTENT_SERVICE_ENABLED: enabled }
      if enabled
        env_hash = env_hash.merge(service_settings)
        if user && domain
          env_hash[:JWT] = Canvas::Security::ServicesJwt.generate(
            sub: user.global_id,
            domain: domain
          )
        end
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

      def contextually_on(root_account, risk_level)
          check_feature_flag(root_account, :rich_content_service) && (
            risk_level == :basic ||
            (risk_level == :sidebar && check_feature_flag(root_account, :rich_content_service_with_sidebar)) ||
            check_feature_flag(root_account, :rich_content_service_high_risk)
          )
      end
    end
  end
end
