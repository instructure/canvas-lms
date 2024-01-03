# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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
    class InvalidLaunch < StandardError; end

    # Contains actions to handle the second step of an LTI 1.3
    # Launch: The authentication request
    class AuthenticationController < ApplicationController
      include Lti::RedisMessageClient
      include Lti::Concerns::ParentFrame

      REQUIRED_PARAMS = %w[
        client_id
        login_hint
        lti_message_hint
        nonce
        prompt
        redirect_uri
        response_mode
        response_type
        scope
      ].freeze
      OPTIONAL_PARAMS = ["state"].freeze
      SCOPE = "openid"

      skip_before_action :load_user, only: :authorize_redirect
      skip_before_action :verify_authenticity_token, only: :authorize_redirect

      # Redirect the "authorize" action for the domain specified
      # in the lti_message_hint
      #
      # This means that tools can simply use the canvas.instructure.com
      # domain in the authentication requests rather than keeping
      # track of institution-specific domain.
      def authorize_redirect
        if Setting.get("interop_8200_session_token_redirect", nil) == "true" ||
           Setting.get("interop_8200_session_token_redirect/#{canvas_domain}", nil) == "true"
          csp_frame_ancestors << canvas_domain
          render template: "shared/html_redirect",
                 layout: false,
                 formats: :html,
                 locals: {
                   url: authorize_redirect_url
                 }
        else
          redirect_to authorize_redirect_url
        end
      end

      # Handles the authentication response from an LTI tool. This
      # is the second step in an LTI 1.3 launch.
      #
      # Please refer to the following specification sections:
      # - https://www.imsglobal.org/spec/security/v1p0#step-2-authentication-request
      # - http://www.imsglobal.org/spec/lti/v1p3/
      #
      # If the authentication validations described in the specifications
      # succeed, this action uses the "lti_message_hint" parameter
      # to retrieve a cached ID token (LTI launch) and sends it to the
      # tool.
      #
      # The cached ID Token is generated at the time Canvas makes
      # the login request to the tool.
      #
      # For more details on how the cached ID token is generated,
      # please refer to the inline documentation of "app/models/lti/lti_advantage_adapter.rb"
      def authorize
        validate_oidc_params!
        validate_current_user!
        validate_client_id!
        validate_launch_eligibility!
        set_extra_csp_frame_ancestor! unless @oidc_error

        render(
          "lti/ims/authentication/authorize",
          formats: :html,
          layout: "borderless_lti",
          locals: {
            redirect_uri:,
            parameters: @oidc_error || launch_parameters
          }
        )

        report_lti_launch_debug_logger_metrics!
      rescue RequestError, ActiveRecord::RecordNotFound => e
        report_lti_launch_debug_logger_metrics!(e)
        raise
      end

      private

      def validate_client_id!
        binding_context = context.respond_to?(:account) ? context.account : context

        unless developer_key.usable? && developer_key.account_binding_for(binding_context)&.workflow_state == "on"
          set_oidc_error!("unauthorized_client", "Client not authorized in requested context")
        end
      end

      def validate_current_user!
        return if public_course? && @current_user.blank?

        if !@current_user || Lti::Asset.opaque_identifier_for(@current_user, context:) != oidc_params[:login_hint]
          report_oidc_invalid_user_metric(@current_user)
          set_oidc_error!("login_required", "Must have an active user session")
        end
      end

      def report_lti_launch_debug_logger_metrics?(error)
        log_level = Lti::LaunchDebugLogger.log_level(@domain_root_account)
        if log_level <= 0
          # Log nothing
          false
        elsif log_level == 1
          # Log only "login_required" errors
          @launch_debug_logger_oidc_errors&.include?("login_required")
        elsif log_level == 2
          # Log all errors except "really bogus" requests like an invalid message hint
          @launch_debug_logger_oidc_errors && !error
        elsif log_level == 3
          # Log all non-"really bogus" requests
          !error
        else
          # Log everything
          true
        end
      end

      def report_lti_launch_debug_logger_metrics!(error = nil)
        return unless report_lti_launch_debug_logger_metrics?(error)

        metrics_endpoint = DynamicSettings.find(tree: :private)["frontend_data_collection_endpoint"]
        return unless metrics_endpoint

        debug_trace_metrics = (@decoded_jwt && Lti::LaunchDebugLogger.decode_debug_trace(@decoded_jwt["debug_trace"])) || {}
        orig_timestamp = debug_trace_metrics&.dig("time")&.then { Time.parse _1 }

        metrics = {
          id: SecureRandom.uuid,
          type: "lti_launch_debug_logger",

          error: error && "#{error.class}: #{error.message}",

          state: oidc_params[:state],
          oidc_errors: @launch_debug_logger_oidc_errors&.then { _1.sort.join(",") },
          user: @current_user&.global_id,
          pseudonym: @current_pseudonym&.global_id,
          host: request.host,
          pseudonym_session_login_error: @pseudonym_session.try(:login_error)&.inspect,
          pseudonym_session_errors: @pseudonym_session.try(:errors)&.inspect,
          pseudonym_session_class: @pseudonym_session.class.name,
          time_since_launch_kickoff: orig_timestamp && (Time.now - orig_timestamp).round(3),

          **Lti::LaunchDebugLogger.request_related_fields(request:, session:, cookies:),

          **debug_trace_metrics.transform_keys { |orig_key| "init_#{orig_key}" }
        }.compact

        CanvasHttp.put(metrics_endpoint, {}, body: metrics.to_json, content_type: "application/json")
      rescue => e
        Rails.logger.warn("Couldn't send OIDC invalid user metric: #{e.inspect}")
      end

      def report_oidc_invalid_user_metric(user)
        dynamic_settings_tree = DynamicSettings.find(tree: :private)
        if dynamic_settings_tree["frontend_data_collection_endpoint"]
          data_collection_endpoint = dynamic_settings_tree["frontend_data_collection_endpoint"]
          session_cookie_present = !request.cookies[Rails.application.config.session_options[:key]].nil?
          current_user_is_nil = user.nil?
          put_body = [{
            id: SecureRandom.uuid,
            type: "oidc_error_invalid_user",
            session_cookie_present:,
            current_user_is_nil:,
            user_agent: request.user_agent,
            host: request.host,
            referer: request.referer,
            request_id: Thread.current[:context].try(:[], :request_id)
          }]
          CanvasHttp.put(data_collection_endpoint, {}, body: put_body.to_json, content_type: "application/json")
        end
      rescue
        Rails.logger.warn("Couldn't send OIDC invalid user metric")
      end

      def validate_oidc_params!
        missing_params = REQUIRED_PARAMS - oidc_params.keys
        if missing_params.present?
          set_oidc_error!("invalid_request_object", "The following parameters are missing: #{missing_params.join(",")}")
        end
        set_oidc_error!("invalid_request_object", "The 'scope' must be '#{SCOPE}'") if oidc_params[:scope] != SCOPE
      end

      def validate_launch_eligibility!
        return if @oidc_error

        id_token
      rescue InvalidLaunch => e
        Canvas::Errors.capture_exception(:lti, e, :info)
        set_oidc_error!("launch_no_longer_valid", "The launch has either expired or already been consumed")
      end

      def set_oidc_error!(error, error_description)
        (@launch_debug_logger_oidc_errors ||= []) << error

        @oidc_error = {
          error:,
          error_description:,
          state: oidc_params[:state]
        }
      end

      def public_course?
        # Is the context published and public?
        context.is_a?(Course) && context&.available? && context&.is_public?
      end

      def verifier
        decoded_jwt["verifier"]
      end

      def canvas_domain
        decoded_jwt["canvas_domain"]
      end

      # Overrides method in Lti::Concerns::ParentFrame; used by set_extra_csp_frame_ancestor!
      def parent_frame_context
        decoded_jwt["parent_frame_context"]
      end

      def context
        @context ||= begin
          model = decoded_jwt["context_type"].constantize
          model.find(decoded_jwt["context_id"])
        end
      end

      def cached_launch_with_nonce
        @cached_launch_with_nonce ||= begin
          launch_payload = fetch_and_delete_launch(context, verifier)
          raise InvalidLaunch, "no payload found in cache" if launch_payload.nil?

          JSON.parse(launch_payload).merge({ nonce: oidc_params[:nonce] })
        end
      end

      def launch_parameters
        @launch_parameters ||= id_token.merge({
          state: oidc_params[:state],
          lti_storage_target:
        }.compact)
      end

      def lti_storage_target
        return nil unless decoded_jwt["include_storage_target"]

        Lti::PlatformStorage.lti_storage_target
      end

      def id_token
        @id_token ||= Lti::Messages::JwtMessage.generate_id_token(cached_launch_with_nonce)
      end

      def authorize_redirect_url
        url = URI.parse(lti_1_3_authorization_url(params: oidc_params))
        parts = canvas_domain.split(":")
        url.host = parts.first
        url.port = parts.last if parts.size > 1
        url.to_s
      end

      def developer_key
        @developer_key ||= DeveloperKey.find_cached(oidc_params[:client_id].to_i)
      end

      def redirect_uri
        @redirect_uri ||= begin
          requested_redirect_base, requested_query_string = oidc_params[:redirect_uri].split("?")
          is_valid = developer_key.redirect_uris.any? do |uri|
            if uri.include? "?"
              # Verify the required query params are present
              required_params = CGI.parse(uri.split("?").last).to_a
              requested_params = CGI.parse(requested_query_string).to_a
              (required_params - requested_params).empty?
            else
              uri == requested_redirect_base
            end
          end

          reject! "Invalid redirect_uri" unless is_valid

          oidc_params[:redirect_uri]
        end
      end

      def oidc_params
        params.permit(*(OPTIONAL_PARAMS + REQUIRED_PARAMS))
      end

      def decoded_jwt
        @decoded_jwt ||= Canvas::Security.decode_jwt(params.require(:lti_message_hint))
      rescue JSON::JWT::InvalidFormat,
             Canvas::Security::InvalidToken,
             Canvas::Security::TokenExpired
        reject! "Invalid lti_message_hint"
      end
    end
  end
end
