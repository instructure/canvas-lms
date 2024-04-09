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
      REGISTRATION_TOKEN_EXPIRATION = 1.hour

      before_action :require_dynamic_registration_flag, except: [:create]
      before_action :require_user, except: [:create]
      before_action :require_account, except: [:create]

      # This skip_before_action is required because :load_user will
      # attempt to find the bearer token, which is not stored with
      # the other Canvas tokens.
      skip_before_action :load_user, only: [:create]

      def require_account
        require_context_with_permission(account_context, :manage_developer_keys)
      end

      def account_context
        require_account_context
        return @context if context_is_domain_root_account?

        # failover to what require_site_admin_with_permission uses
        Account.site_admin
      end

      def context_is_domain_root_account?
        @context == @domain_root_account
      end

      def registration_token
        uuid = SecureRandom.uuid
        current_time = DateTime.now.iso8601
        user_id = @current_user.id
        root_account_global_id = account_context.global_id
        token = Canvas::Security.create_jwt(
          {
            uuid:,
            initiated_at: current_time,
            user_id:,
            root_account_global_id:
          },
          REGISTRATION_TOKEN_EXPIRATION.from_now
        )

        render json: {
          uuid:,
          oidc_configuration_url: oidc_configuration_url(token),
          token:
        }
      end

      def registration_by_uuid
        render json: Lti::IMS::Registration.find_by(guid: params[:registration_uuid])
      end

      def oidc_configuration_url(registration_token)
        issuer_url = Canvas::Security.config["lti_iss"]
        parsed_issuer = Addressable::URI.parse(issuer_url)
        issuer_domain = if Rails.env.development?
                          HostUrl.context_host(@domain_root_account, request.host)
                        else
                          parsed_issuer.host
                        end
        issuer_protocol = parsed_issuer.scheme
        issuer_port = parsed_issuer.port

        openid_configuration_url(protocol: issuer_protocol, port: issuer_port, host: issuer_domain, registration_token:)
      end

      def update_registration_overlay
        registration = Lti::IMS::Registration.find(params[:registration_id])
        # TODO: validate overlay against a schema
        registration.registration_overlay = JSON.parse(request.body.read)
        registration.save!
        registration.update_external_tools!
        render json: registration
      end

      def create
        access_token = AuthenticationMethods.access_token(request)
        jwt = Canvas::Security.decode_jwt(access_token)

        expected_jwt_keys = %w[user_id initiated_at root_account_global_id exp uuid]

        if jwt.keys.sort != expected_jwt_keys.sort
          respond_with_error(:unauthorized, "JWT did not include expected contents")
          return
        end

        root_account = Account.find(jwt["root_account_global_id"])
        if root_account.nil?
          Rails.logger.info "Couldn't find root account: #{jwt.inspect}"
          respond_with_error(:not_found, "Specified account does not exist")
          return
        end

        unless root_account.feature_enabled? :lti_dynamic_registration
          render status: :not_found, template: "shared/errors/404_message"
          return
        end

        root_account.shard.activate do
          registration_params = params.permit(*expected_registration_params)
          registration_params["lti_tool_configuration"] = registration_params["https://purl.imsglobal.org/spec/lti-tool-configuration"]
          registration_params.delete("https://purl.imsglobal.org/spec/lti-tool-configuration")
          scopes = registration_params["scope"].split
          registration_params.delete("scope")

          developer_key = DeveloperKey.new(
            name: registration_params["client_name"],
            account: root_account.site_admin? ? nil : root_account,
            redirect_uris: registration_params["redirect_uris"],
            public_jwk_url: registration_params["jwks_uri"],
            oidc_initiation_url: registration_params["initiate_login_uri"],
            is_lti_key: true,
            scopes:,
            icon_url: registration_params["logo_uri"]
          )
          registration = Lti::IMS::Registration.new(
            developer_key:,
            root_account_id: root_account.id,
            scopes:,
            guid: jwt["uuid"],
            **registration_params
          )

          ActiveRecord::Base.transaction do
            developer_key.save!
            registration.save!
          end

          render_registration(registration, developer_key) if registration.persisted?
        end
      end

      def registration_view
        registration = Lti::IMS::Registration.find(params[:registration_id])
        redirect_to account_developer_key_view_url(registration.root_account_id, registration.developer_key_id)
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
          logo_uri: developer_key.icon_url,
          token_endpoint_auth_method: registration.token_endpoint_auth_method,
          scope: registration.scopes.join(" "),
          "https://purl.imsglobal.org/spec/lti-tool-configuration": registration.lti_tool_configuration.merge(
            {
              "https://#{Lti::IMS::Registration::CANVAS_EXTENSION_LABEL}/lti/registration_config_url": lti_registration_config_url(registration.global_id),
            }
          ),
        }
      end

      def respond_with_error(status_code, message)
        head status_code
        render json: {
          errorMessage: message
        }
      end

      def require_dynamic_registration_flag
        unless account_context.feature_enabled? :lti_dynamic_registration
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
            {
              messages:
              [
                :type,
                :target_link_uri,
                :label,
                :icon_uri,
                { custom_parameters: ArbitraryStrongishParams::ANYTHING },
                { roles: [] },
                { placements: [] },
                Lti::IMS::Registration::COURSE_NAV_DEFAULT_ENABLED_EXTENSION,
                Lti::IMS::Registration::PLACEMENT_VISIBILITY_EXTENSION
              ]
            },
            { claims: [] },
            :target_link_uri,
            { custom_parameters: ArbitraryStrongishParams::ANYTHING },
            "https://#{Lti::IMS::Registration::CANVAS_EXTENSION_LABEL}/lti/privacy_level"
          ] },
          :client_uri,
          :logo_uri,
          :tos_uri,
          :policy_uri,
        ]
      end
    end
  end
end
