# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

module Lti
  module IMS
    class DynamicRegistrationController < ApplicationController
      include Lti::Oidc

      REGISTRATION_TOKEN_EXPIRATION = 1.hour

      before_action :require_dynamic_registration_flag,
                    :require_user

      def create
        tool_registration_url = params.require(:registration_url) # redirect to this
        issuer_url = Canvas::Security.config["lti_iss"]
        parsed_issuer = Addressable::URI.parse(issuer_url)
        issuer_domain = if Rails.env.development?
                          HostUrl.context_host(@domain_root_account, request.host)
                        else
                          parsed_issuer.host
                        end
        issuer_protocol = parsed_issuer.scheme
        issuer_port = parsed_issuer.port

        current_time = DateTime.now.iso8601
        user_id = @current_user.id
        root_account_global_id = @domain_root_account.global_id
        oidc_configuration_url = openid_configuration_url(protocol: issuer_protocol, port: issuer_port, domain: issuer_domain)

        jwt = Canvas::Security.create_jwt({
                                            initiated_at: current_time,
                                            user_id:,
                                            root_account_global_id:
                                          },
                                          REGISTRATION_TOKEN_EXPIRATION.from_now)

        redirection_url = Addressable::URI.parse(tool_registration_url)
        redirection_url_params = redirection_url.query_values || {}
        redirection_url_params[:registration_token] = jwt
        redirection_url_params[:openid_configuration] = oidc_configuration_url

        redirection_url.query_values = redirection_url_params

        redirect_to redirection_url.to_s
      end

      private

      def require_dynamic_registration_flag
        unless @domain_root_account.feature_enabled? :lti_dynamic_registration
          render status: :not_found, template: "shared/errors/404_message"
        end
      end
    end
  end
end
