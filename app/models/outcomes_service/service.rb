# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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
#

module OutcomesService
  class Service
    class << self
      def url(context)
        settings = settings(context)
        protocol = ENV.fetch("OUTCOMES_SERVICE_PROTOCOL", Rails.env.production? ? "https" : "http")
        domain = settings[domain_key]
        "#{protocol}://#{domain}" if domain.present?
      end

      def domain_key
        # test_cluster? and test_cluster_name are true and not nil for nonprod environments,
        # like beta or test
        if ApplicationController.test_cluster?
          :"#{ApplicationController.test_cluster_name}_domain"
        else
          :domain
        end
      end

      def enabled_in_context?(context)
        settings = settings(context)
        settings[:consumer_key].present? && settings[:jwt_secret].present? && settings[domain_key].present?
      end

      def jwt(context, scope, expiration = 1.day.from_now.to_i, overrides: {})
        if enabled_in_context?(context)
          settings = settings(context)
          consumer_key = settings[:consumer_key]
          jwt_secret = settings[:jwt_secret]
          domain = settings[domain_key]
          payload = {
            host: domain,
            consumer_key:,
            scope:,
            exp: expiration
          }.merge(overrides)
          JWT.encode(payload, jwt_secret, "HS512")
        end
      end

      def toggle_feature_flag(root_account, feature_flag, state)
        feature_flag_url = "#{url(root_account)}/api/features/#{state ? "enable" : "disable"}"
        response = CanvasHttp.post(
          feature_flag_url,
          headers_for(root_account, "features.manage"),
          form_data: {
            feature_flag:
          }
        )
        return unless response && response.code != "204"

        Canvas::Errors.capture(
          "Unexpected response from Outcomes Service toggling feature flag",
          status_code: response.code,
          body: response.body
        )
      end

      private

      def headers_for(context, scope, overrides = {})
        {
          "Authorization" => OutcomesService::Service.jwt(context, scope, overrides:)
        }
      end

      def settings(context)
        context.root_account.settings.dig(:provision, "outcomes") || {}
      end
    end
  end
end
