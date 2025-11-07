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
    # Implements the 1EdTech LTI 1.3 Dynamic Registration <a href="file.registration.html">spec</a>.
    # See the <a href="file.registration.html">Registration guide</a> for how to use this API.
    class DynamicRegistrationController < ApplicationController
      REGISTRATION_TOKEN_EXPIRATION = 1.hour

      before_action :require_user, except: %i[create update show_configuration]
      before_action :require_account, except: %i[create update show_configuration]

      # This skip_before_action is required because :load_user will
      # attempt to find the bearer token, which is not stored with
      # the other Canvas tokens.
      skip_before_action :load_user, only: %i[create update show_configuration]

      include Api::V1::Lti::Registration
      include Api::V1::Lti::RegistrationUpdateRequest

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
        root_account_domain = account_context.domain(request.host)
        unified_tool_id = params[:unified_tool_id].presence
        registration_url = params[:registration_url]
        existing_registration = Lti::Registration.find(params[:registration_id]) if params[:registration_id].present? && account_context.feature_enabled?(:lti_dr_registrations_update)

        token = Canvas::Security.create_jwt(
          {
            uuid:,
            initiated_at: current_time,
            user_id:,
            unified_tool_id:,
            root_account_global_id:,
            root_account_domain:,
            registration_url:,
            existing_registration: existing_registration&.id
          }.compact,
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

      def lti_registration_update_request_by_uuid
        registration_update_request = Lti::RegistrationUpdateRequest.find_by!(uuid: params[:registration_uuid])
        render json: lti_registration_update_request_json(registration_update_request, @current_user, session, @context)
      end

      def ims_registration_by_uuid
        render json: Lti::IMS::Registration.find_by!(guid: params[:registration_uuid]).as_json(context: account_context)
      end

      def show
        render json: Lti::IMS::Registration.find(params[:registration_id]).as_json(context: account_context)
      end

      # @API Get Dynamic Registration Configuration
      # Retrieves the LTI Dynamic Registration configuration for a given registration.
      # This endpoint provides the complete registration configuration including client details,
      # scopes, redirect URIs, and LTI tool configuration. Authentication is required via
      # developer key access token with appropriate LTI registration scopes.
      #
      # @argument registration_id [Required, Integer] The ID of the LTI IMS Registration to retrieve configuration for
      #
      # @returns {Object} LTI Dynamic Registration configuration containing:
      #   - client_id: The global developer key ID as a string
      #   - application_type: Always "web" for LTI registrations
      #   - grant_types: Array of supported OAuth2 grant types
      #   - initiate_login_uri: URL for LTI login initiation
      #   - redirect_uris: Array of allowed redirect URIs after authentication
      #   - response_types: Array of supported OAuth2 response types (always "id_token")
      #   - client_name: Display name of the LTI tool
      #   - jwks_uri: URL to the tool's JSON Web Key Set
      #   - logo_uri: URL to the tool's logo/icon
      #   - token_endpoint_auth_method: Authentication method (always "private_key_jwt")
      #   - scope: Space-separated string of OAuth2 scopes including LTI scopes and "openid"
      #   - LTI tool configuration object with placements and Canvas-specific extensions
      #   - registration_client_uri: URL to view/manage the registration in Canvas
      #   - deployment_id: The deployment ID for the root account deployment (if exists)
      #
      # @example_request
      #
      #   This would return the Dynamic Registration configuration for the specified registration
      #   curl -X GET 'https://<canvas>/api/lti/registrations/<registration_id>/configuration' \
      #        -H "Authorization: Bearer <developer_key_access_token>"
      #
      # @example_response
      #   {
      #     "client_id": "10000000000001",
      #     "application_type": "web",
      #     "grant_types": ["client_credentials", "implicit"],
      #     "initiate_login_uri": "https://tool.example.com/login",
      #     "redirect_uris": ["https://tool.example.com/redirect"],
      #     "response_types": ["id_token"],
      #     "client_name": "Example LTI Tool",
      #     "jwks_uri": "https://tool.example.com/.well-known/jwks.json",
      #     "logo_uri": "https://tool.example.com/logo.png",
      #     "token_endpoint_auth_method": "private_key_jwt",
      #     "scope": "https://purl.imsglobal.org/spec/lti-ags/scope/lineitem openid",
      #     "https://purl.imsglobal.org/spec/lti-tool-configuration": {
      #       "domain": "tool.example.com",
      #       "description": "An example LTI 1.3 tool",
      #       "target_link_uri": "https://tool.example.com/launch",
      #       "claims": ["iss", "sub"],
      #       "messages": [
      #         {
      #           "type": "LtiResourceLinkRequest",
      #           "placements": ["course_navigation"]
      #         }
      #       ],
      #       "https://canvas.instructure.com/lti/registration_config_url": "https://canvas.example.com/api/lti/registrations/123/view"
      #     },
      #     "registration_client_uri": "https://canvas.example.com/api/lti/registrations/123",
      #     "deployment_id": "1:abc123def456"
      #   }
      def show_configuration
        validation_result = Lti::TokenValidationService.verify_developer_key_access_token_and_scopes(
          request,
          Lti::ScopeMatchers.any_of(TokenScopes::LTI_REGISTRATION_SCOPE, TokenScopes::LTI_REGISTRATION_READ_ONLY_SCOPE)
        )

        unless validation_result[:success]
          return render status: validation_result[:status], json: { errorMessage: validation_result[:error] }
        end

        ims_registration = Lti::IMS::Registration.find(params[:registration_id])
        root_deployment = ContextExternalTool.find_by(account: ims_registration.root_account, lti_registration: ims_registration.lti_registration_id)
        render_registration(ims_registration, ims_registration.developer_key, root_deployment)
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

        required_jwt_keys = %w[user_id initiated_at root_account_global_id root_account_domain exp uuid registration_url]
        unless required_jwt_keys.all? { |key| jwt.key?(key) }
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
          { errors:, registration_attrs: }
        return render status: :unprocessable_entity, json: { errors: } if errors.present?

        if jwt["existing_registration"].present?
          registration = Lti::Registration.find(jwt["existing_registration"])
          if registration.present?
            # Create an LTI RegistrationUpdateRequest
            # to update the existing registration
            registration_update_request = Lti::RegistrationUpdateRequest.new(
              root_account_id: registration.root_account.id,
              lti_registration_id: registration.id,
              uuid: jwt["uuid"],
              lti_ims_registration: registration_attrs,
              created_by_id: jwt["user_id"],
              accepted_at: nil,
              rejected_at: nil
            )

            root_deployment = ContextExternalTool.find_by(account: root_account, lti_registration: registration)

            render_registration(registration.ims_registration, registration.developer_key, root_deployment) if registration_update_request.save
            return
          end
        end

        registration_url = jwt["registration_url"]

        root_account.shard.activate do
          current_user = User.find(jwt["user_id"])
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

          deployment = nil

          ActiveRecord::Base.transaction do
            developer_key.save!
            ims_registration.save!
            registration.save!

            if root_account.feature_enabled?(:lti_registrations_next)
              deployment = registration.new_external_tool(root_account, current_user:, available: false, enabled: false)
            end
          end

          render_registration(ims_registration, developer_key, deployment) if ims_registration.persisted?
        end
      end

      def update
        ims_registration = Lti::IMS::Registration.find(params[:registration_id])
        registration = ims_registration.lti_registration
        unless registration.root_account.feature_enabled?(:lti_dr_registrations_update)
          respond_to do |format|
            format.html { render "shared/errors/404_message", status: :not_found }
            format.json { render_error(:not_found, "The specified resource does not exist.", status: :not_found) }
          end
        end

        validation_result = Lti::TokenValidationService.verify_developer_key_access_token_and_scopes(
          request,
          Lti::ScopeMatchers.all_of(TokenScopes::LTI_REGISTRATION_SCOPE)
        )

        unless validation_result[:success]
          return render status: validation_result[:status], json: { errorMessage: validation_result[:error] }
        end

        # create a registration update request based on the body
        # of the request and the registration id
        Schemas::Lti::IMS::OidcRegistration.to_model_attrs(params.to_unsafe_h) =>
          { errors:, registration_attrs: }
        return render status: :unprocessable_entity, json: { errors: } if errors.present?

        if registration.present?
          # Create an LTI RegistrationUpdateRequest
          # to update the existing registration
          registration_update_request = Lti::RegistrationUpdateRequest.new(
            root_account_id: registration.root_account.id,
            lti_registration_id: registration.id,
            uuid: nil,
            lti_ims_registration: registration_attrs,
            created_by_id: nil,
            accepted_at: nil,
            rejected_at: nil
          )

          root_deployment = ContextExternalTool.find_by(account: registration.root_account, developer_key: registration.developer_key)

          render_registration(ims_registration, registration.developer_key, root_deployment) if registration_update_request.save
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

      def render_registration(registration, developer_key, deployment)
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
          scope: (registration.scopes + ["openid"]).join(" "),
          "https://purl.imsglobal.org/spec/lti-tool-configuration": registration.lti_tool_configuration.merge(
            {
              "https://#{Lti::IMS::Registration::CANVAS_EXTENSION_LABEL}/lti/registration_config_url": lti_registration_config_url(registration.global_id),
            }
          ),
          registration_client_uri: get_lti_registration_url(registration_id: registration.global_id),
          deployment_id: deployment&.deployment_id
        }.compact
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
