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

      before_action :require_dynamic_registration_flag
      before_action :require_user, except: [:create]

      def redirect_to_tool_registration
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
        oidc_configuration_url = openid_configuration_url(protocol: issuer_protocol, port: issuer_port, host: issuer_domain)
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

      def create
        token_param = params.require(:registration_token)
        jwt = Canvas::Security.decode_jwt(token_param)

        expected_jwt_keys = %w[user_id initiated_at root_account_global_id exp]

        if jwt.keys.sort != expected_jwt_keys.sort
          respond_with_error(:unprocessable_entity, "JWT did not include expected contents")
        end

        root_account = Account.find(jwt["root_account_global_id"])
        respond_with_error(:not_found, "Specified account does not exist") unless root_account

        root_account.shard.activate do
          registration_params = params.permit(*expected_registration_params)
          registration_params["lti_tool_configuration"] = registration_params["https://purl.imsglobal.org/spec/lti-tool-configuration"]
          registration_params.delete("https://purl.imsglobal.org/spec/lti-tool-configuration")
          scopes = registration_params["scope"].split
          registration_params.delete("scope")

          developer_key = DeveloperKey.new(
            name: registration_params["client_name"],
            account: root_account,
            redirect_uris: registration_params["redirect_uris"],
            public_jwk_url: registration_params["jwks_uri"],
            oidc_initiation_url: registration_params["initiate_login_uri"],
            is_lti_key: true
          )
          registration = Lti::IMS::Registration.new(
            developer_key:,
            root_account_id: root_account.id,
            scopes:,
            **registration_params
          )

          ActiveRecord::Base.transaction do
            developer_key.save!
            registration.save!
          end

          render_registration(registration, developer_key) if registration.persisted?
        end
      end

      private

      def render_registration(registration, developer_key)
        render json: {
          client_id: developer_key.global_id.to_s,
          application_type: registration.application_type,
          grant_types: registration.grant_types,
          initiate_login_uri: registration.initiate_login_uri,
          redirect_uris: registration.redirect_uris,
          response_types: registration.response_types,
          client_name: registration.client_name,
          jwks_uri: registration.jwks_uri,
          token_endpoint_auth_method: registration.token_endpoint_auth_method,
          scope: registration.scopes.join(" "),
          "https://purl.imsglobal.org/spec/lti-tool-configuration": registration.lti_tool_configuration
        }
      end

      def respond_with_error(status_code, message)
        head status_code
        render json: {
          errorMessage: message
        }
      end

      def require_dynamic_registration_flag
        unless @domain_root_account.feature_enabled? :lti_dynamic_registration
          render status: :not_found, template: "shared/errors/404_message"
        end
      end

      def expected_registration_params
        [
          :application_type,
          { grant_types: [] },
          { response_types: [] },
          { redirect_uris: [] },
          :initiate_login_uri,
          :client_name,
          :jwks_uri,
          :scope,
          :token_endpoint_auth_method,
          { "https://purl.imsglobal.org/spec/lti-tool-configuration" => [
            :domain,
            { messages: [:type, :target_link_uri, :label, :icon_uri, { custom_parameters: ArbitraryStrongishParams::ANYTHING }, { roles: [] }, { placements: [] }] },
            { claims: [] },
            :target_link_uri,
          ] },
          :target_link_uri,
        ]
      end
    end
  end
end
