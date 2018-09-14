#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

module Services
  class RichContent
    def self.env_for(root_account, risk_level: :highrisk, user: nil, domain: nil, real_user: nil, context: nil)
      enabled = contextually_on(root_account, risk_level)
      env_hash = { RICH_CONTENT_SERVICE_ENABLED: enabled }
      if enabled
        env_hash = env_hash.merge(service_settings)
        if user && domain
          begin
            env_hash[:JWT] = Canvas::Security::ServicesJwt.for_user(
              domain,
              user,
              context: context,
              real_user: real_user,
              workflows: [:rich_content, :ui]
            )
          rescue Canvas::Security::InvalidJwtKey => exception
            Canvas::Errors.capture_exception(:jwt, exception)
            env_hash[:JWT] = "InvalidJwtKey"
          end
        end

        # TODO: Remove once rich content service pull from jwt
        env_hash[:RICH_CONTENT_CAN_UPLOAD_FILES] = (
          user &&
          context &&
          context.grants_any_right?(user, :manage_files)
        ) || false
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
        settings = Canvas::DynamicSettings.find("rich-content-service", default_ttl: 5.minutes)
        {
          RICH_CONTENT_APP_HOST: settings['app-host'],
          RICH_CONTENT_CDN_HOST: settings['cdn-host'],
          RICH_CONTENT_SKIP_SIDEBAR: settings['skip-sidebar']
        }
      rescue Imperium::TimeoutError,
        Imperium::UnableToConnectError,
        Canvas::DynamicSettings::ConsulError => e
        Canvas::Errors.capture_exception(:rce_flag, e)
        {
          RICH_CONTENT_APP_HOST: "error",
          RICH_CONTENT_CDN_HOST: "error"
        }
      end

      def contextually_on(root_account, _risk_level)
        enabled = Setting.get('rich_content_service_enabled', 'false') == 'true'
        enabled || check_feature_flag(root_account, :rich_content_service_high_risk)
      end
    end
  end
end
