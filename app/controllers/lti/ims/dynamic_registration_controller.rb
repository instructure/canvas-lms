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

      before_action :require_user, except: [:create]
      before_action :require_account, except: [:create]

      # This skip_before_action is required because :load_user will
      # attempt to find the bearer token, which is not stored with
      # the other Canvas tokens.
      skip_before_action :load_user, only: [:create]

      include Api::V1::Lti::Registration

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
        current_time = Time.zone.now.iso8601
        user_id = @current_user.id
        root_account_global_id = account_context.global_id
        unified_tool_id = params[:unified_tool_id].presence
        registration_url = params[:registration_url]

        token = Canvas::Security.create_jwt(
          {
            uuid:,
            initiated_at: current_time,
            user_id:,
            unified_tool_id:,
            root_account_global_id:,
            registration_url:
          },
          REGISTRATION_TOKEN_EXPIRATION.from_now
        )

        render json: {
          uuid:,
          oidc_configuration_url: oidc_configuration_url(token),
          token:
        }
      end

      def lti_registration_by_uuid
        reg = Lti::IMS::Registration.find_by!(guid: params[:registration_uuid])
        render json: lti_registration_json(reg.lti_registration,
                                           @current_user,
                                           session,
                                           @context,
                                           includes: %i[configuration overlay],
                                           overlay: reg.lti_registration.overlay_for(@context))
      end

      def ims_registration_by_uuid
        render json: Lti::IMS::Registration.find_by!(guid: params[:registration_uuid]).as_json(context: account_context)
      end

      def show
        render json: Lti::IMS::Registration.find(params[:registration_id]).as_json(context: account_context)
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
        # Historically, the overlay for an IMS Registration lived on its
        # registration_overlay column. However, we're transitioning over to using
        # the Lti::Overlay and Lti::Registration models, so that more than just Dynamic
        # Registrations can be overlaid, hence the reason for keeping two data
        # sources in sync.
        Lti::IMS::Registration.transaction do
          registration_overlay = JSON.parse(request.body.read)
          overlay = registration.lti_registration.overlay_for(@context)

          # Let the registration validate the data they passed
          registration.update!(registration_overlay:)

          # also update the DK scopes
          if registration_overlay["disabledScopes"].present?
            registration.developer_key.update!(scopes: registration.scopes - registration_overlay["disabledScopes"])
          end

          data = Schemas::Lti::IMS::RegistrationOverlay.to_lti_overlay(registration_overlay)

          if overlay.blank?
            Lti::Overlay.create!(registration: registration.lti_registration,
                                 updated_by: @current_user,
                                 account: account_context,
                                 data:)
          else
            overlay.update!(data:, updated_by: @current_user)
          end
          registration.update_external_tools!
        end
        render json: registration
      end

      # @API Create a Dynamic Registration
      # The final step of the Dynamic Registration process.
      # Refer to the Registration guide linked at the top of this page for usage of this endpoint.
      # Requires special Dynamic Registration token and is not for out-of-band use.
      def create
        access_token = AuthenticationMethods.access_token(request)
        jwt = Canvas::Security.decode_jwt(access_token)

        expected_jwt_keys = %w[user_id initiated_at root_account_global_id exp uuid unified_tool_id registration_url]
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

        Schemas::Lti::IMS::OidcRegistration.to_model_attrs(params.to_unsafe_h) =>
          {errors:, registration_attrs:}
        return render status: :unprocessable_entity, json: { errors: } if errors.present?

        registration_url = jwt["registration_url"]
        current_user = User.find(jwt["user_id"])

        root_account.shard.activate do
          developer_key = DeveloperKey.new(
            current_user:,
            name: registration_attrs["client_name"],
            account: root_account.site_admin? ? nil : root_account,
            redirect_uris: registration_attrs["redirect_uris"],
            public_jwk_url: registration_attrs["jwks_uri"],
            oidc_initiation_url: registration_attrs["initiate_login_uri"],
            is_lti_key: true,
            scopes: registration_attrs["scopes"],
            icon_url: registration_attrs["logo_uri"],
            skip_lti_sync: true
          )

          ims_registration = Lti::IMS::Registration.new(
            developer_key:,
            root_account_id: root_account.id,
            guid: jwt["uuid"],
            unified_tool_id: jwt["unified_tool_id"],
            registration_url:,
            **registration_attrs
          )

          registration = Lti::Registration.new(
            developer_key:,
            account: root_account,
            created_by: current_user,
            updated_by: current_user,
            admin_nickname: registration_attrs["client_name"],
            name: registration_attrs["client_name"],
            vendor: ims_registration.vendor,
            ims_registration:
          )

          ActiveRecord::Base.transaction do
            developer_key.save!
            ims_registration.save!
            registration.save!

            if root_account.feature_enabled?(:lti_registrations_next)
              registration.new_external_tool(root_account, current_user:, available: false)
            end
          end

          render_registration(ims_registration, developer_key) if ims_registration.persisted?
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
          response_types: [Lti::IMS::Registration::REQUIRED_RESPONSE_TYPE],
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
    end
  end
end
