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
    # @API LTI Dynamic Registrations
    # @internal
    # Implements the 1EdTech LTI 1.3 Dynamic Registration <a href="/doc/api/registration.html">spec</a>.
    # See the <a href="/doc/api/registration.html">Registration guide</a> for how to use this API.
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
        unified_tool_id = params[:unified_tool_id].presence

        token = Canvas::Security.create_jwt(
          {
            uuid:,
            initiated_at: current_time,
            user_id:,
            unified_tool_id:,
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
        issuer_protocol = request.scheme if Rails.env.development?
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

      # @API Create a Dynamic Registration
      # The final step of the Dynamic Registration process.
      # Refer to the Registration guide linked at the top of this page for usage of this endpoint.
      # Requires special Dynamic Registration token and is not for out-of-band use.
      def create
        access_token = AuthenticationMethods.access_token(request)
        jwt = Canvas::Security.decode_jwt(access_token)

        expected_jwt_keys = %w[user_id initiated_at root_account_global_id exp uuid unified_tool_id]

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

        registration_params = params.permit(*expected_registration_params)
        registration_params["lti_tool_configuration"] = registration_params["https://purl.imsglobal.org/spec/lti-tool-configuration"]
        registration_params.delete("https://purl.imsglobal.org/spec/lti-tool-configuration")
        scopes = registration_params["scope"].split
        registration_params.delete("scope")
        error_messages = validate_registration_params(registration_params)

        if error_messages.present?
          render status: :unprocessable_entity, json: { errors: error_messages }
          return
        end

        root_account.shard.activate do
          developer_key = DeveloperKey.new(
            current_user: User.find(jwt["user_id"]),
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
            unified_tool_id: jwt["unified_tool_id"],
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

      def dr_iframe
        @dr_url = params.require(:url)
        token = CGI.parse(URI.parse(@dr_url).query)["registration_token"].first
        jwt = Canvas::Security.decode_jwt(token)

        if jwt["root_account_global_id"] != @context.global_id
          render status: :unauthorized,
                 json: {
                   errorMessage: "Invalid root_account_id in registration_token"
                 }
          return
        end
        if jwt["user_id"] != @current_user.id
          render status: :unauthorized,
                 json: {
                   errorMessage: "registration_token was created for a different user"
                 }
          return
        end
        request.env["dynamic_reg_url_csp"] = @dr_url
        render("lti/ims/dynamic_registration/dr_iframe", layout: false, formats: :html)
      end

      private

      def render_registration(registration, developer_key)
        render json: {
          client_id: developer_key.global_id.to_s,
          application_type: Lti::IMS::Registration::REQUIRED_APPLICATION_TYPE,
          grant_types: Lti::IMS::Registration::REQUIRED_GRANT_TYPES,
          initiate_login_uri: registration.initiate_login_uri,
          redirect_uris: registration.redirect_uris,
          response_types: Lti::IMS::Registration::REQUIRED_RESPONSE_TYPES,
          client_name: registration.client_name,
          jwks_uri: registration.jwks_uri,
          logo_uri: developer_key.icon_url,
          token_endpoint_auth_method: Lti::IMS::Registration::REQUIRED_TOKEN_ENDPOINT_AUTH_METHOD,
          scope: registration.scopes.join(" "),
          "https://purl.imsglobal.org/spec/lti-tool-configuration": registration.lti_tool_configuration.merge(
            {
              "https://#{Lti::IMS::Registration::CANVAS_EXTENSION_LABEL}/lti/registration_config_url": lti_registration_config_url(registration.global_id),
            }
          ),
        }
      end

      def respond_with_error(status_code, message)
        render status: status_code,
               json: {
                 errorMessage: message
               }
      end

      def validate_registration_params(registration_params)
        grant_types = registration_params.delete("grant_types") || []
        response_types = registration_params.delete("response_types") || []
        application_type = registration_params.delete("application_type")
        token_endpoint_auth_method = registration_params.delete("token_endpoint_auth_method")
        errors = []
        if (Lti::IMS::Registration::REQUIRED_GRANT_TYPES - grant_types).present?
          errors << { field: :grant_types, message: "Must include #{Lti::IMS::Registration::REQUIRED_GRANT_TYPES.join(", ")}" }
        end
        if (Lti::IMS::Registration::REQUIRED_RESPONSE_TYPES - response_types).present?
          errors << { field: :response_types, message: "Must include #{Lti::IMS::Registration::REQUIRED_RESPONSE_TYPES.join(", ")}" }
        end

        if token_endpoint_auth_method != Lti::IMS::Registration::REQUIRED_TOKEN_ENDPOINT_AUTH_METHOD
          errors << { field: :token_endpoint_auth_method, message: "Must be 'private_key_jwt'" }
        end

        if application_type != Lti::IMS::Registration::REQUIRED_APPLICATION_TYPE
          errors << { field: :application_type, message: "Must be 'web'" }
        end
        errors
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
            "https://#{Lti::IMS::Registration::CANVAS_EXTENSION_LABEL}/lti/privacy_level",
            "https://#{Lti::IMS::Registration::CANVAS_EXTENSION_LABEL}/lti/tool_id"
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
