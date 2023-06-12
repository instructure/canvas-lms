# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

# Parses/validates an LTI Advantage Access Token (used for LTI Advantage
# endpoints) and caches the result (token, error, or neither) in the request's
# `env`. The token needs to be used in multiple places in the request cycle, so
# this way we can parse and validate it once for all uses.
module Lti
  module IMS
    module AdvantageAccessTokenRequestHelper
      module_function

      REQUEST_ENV_KEY = "canvas.lti_advantage_token"

      # While we migrate over from using canvas.instructure.com as the universal host to sso.canvaslms.com,
      # we have to include both of them. These are simply stored in the config as a comma-separated list.
      # When the migration is done, this will go back to being a single host.
      UNIVERSAL_GRANT_HOSTS = Canvas::Security.config["lti_grant_host"]&.split(",") ||
                              ["canvas.instructure.com", "sso.canvaslms.com"]

      # Will only return a token if there is a valid one
      def token(request)
        token_info(request)[:token]
      end

      def token_error(request)
        token_info(request)[:error]
      end

      def token_info(request)
        request.env[REQUEST_ENV_KEY] ||=
          if (raw_jwt_str = AuthenticationMethods.access_token(request))
            begin
              token = AdvantageAccessToken.new(raw_jwt_str)
              token.validate!(expected_audience(request))
              { token: }
            rescue Lti::IMS::AdvantageErrors::AdvantageClientError => e
              # otherwise it's a system error, so we want normal error trapping and rendering to kick in
              { error: e }
            end
          else
            {}
          end
      end

      def expected_audience(request)
        [
          request.host_with_port,
          *extra_expected_audience_hosts(request),
          *UNIVERSAL_GRANT_HOSTS
        ].uniq.map do |h|
          Rails.application.routes.url_helpers.oauth2_token_url(host: h, protocol: request.protocol)
        end
      end

      # Overridden in MRA
      def extra_expected_audience_hosts(_request)
        []
      end

      # Checks that the route uses a controller that includes LtiServices
      def lti_advantage_route?(request)
        # Currently, all LTI Advantage routes start with /api/lti/. So, we can
        # check the path first so we don't waste time with the relatively-slow
        # controller check for the 99+% of the traffic that isn't an LTI endpoint
        return false unless request&.fullpath&.start_with?("/api/lti/")

        begin
          controller_name = Rails.application.routes.recognize_path(
            request.env["PATH_INFO"],
            method: request.env["REQUEST_METHOD"]
          )&.dig(:controller)
        rescue ActionController::RoutingError
          return false
        end

        return false unless controller_name

        begin
          controller_class = "#{controller_name}_controller".classify.constantize
        rescue NameError
          return false
        end

        controller_class.include?(Lti::IMS::Concerns::LtiServices)
      end
    end
  end
end
