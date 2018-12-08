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
  module Ims
    class AuthenticationController < ApplicationController
      include Lti::RedisMessageClient

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
      OPTIONAL_PARAMS = ['state'].freeze
      SCOPE = 'openid'.freeze

      skip_before_action :load_user, only: :authorize_redirect
      skip_before_action :verify_authenticity_token, only: :authorize_redirect

      # Redirect the "authorize" action for the domain specified
      # in the lti_message_hint
      def authorize_redirect
        redirect_to authorize_redirect_url
      end

      def authorize
        validate_oidc_params!
        validate_current_user!
        validate_client_id!

        render(
          'lti/ims/authentication/authorize.html.erb',
          layout: 'borderless_lti',
          locals: {
            redirect_uri: redirect_uri,
            parameters: @oidc_error || id_token
          }
        )
      end

      private

      def validate_client_id!
        binding_context = context.respond_to?(:account) ? context.account : context

        unless developer_key.usable? && developer_key.account_binding_for(binding_context).workflow_state == 'on'
          set_oidc_error!('unauthorized_client', 'Client not authorized in requested context')
        end
      end

      def validate_current_user!
        if Lti::Asset.opaque_identifier_for(@current_user) != oidc_params[:login_hint]
          set_oidc_error!('login_required', 'The user is not logged in')
        end
      end

      def validate_oidc_params!
        missing_params = REQUIRED_PARAMS - oidc_params.keys
        if missing_params.present?
          set_oidc_error!('invalid_request_object', "The following parameters are missing: #{missing_params.join(',')}")
        end
        set_oidc_error!('invalid_request_object', "The 'scope' must be '#{SCOPE}'") if oidc_params[:scope] != SCOPE
      end

      def set_oidc_error!(error, error_description)
        @oidc_error = {
          error: error,
          error_description: error_description,
          state: oidc_params[:state]
        }
      end

      def verifier
        decoded_jwt['verifier']
      end

      def canvas_domain
        decoded_jwt['canvas_domain']
      end

      def context
        @context ||= begin
          model = decoded_jwt['context_type'].constantize
          model.find(decoded_jwt['context_id'])
        end
      end

      def cached_launch_with_nonce
        @cached_launch_with_nonce ||= begin
          JSON.parse(
            fetch_and_delete_launch(
              context,
              verifier
            )
          ).merge({nonce: oidc_params[:nonce]})
        end
      end

      def id_token
        @id_token ||= begin
          Lti::Messages::JwtMessage.generate_id_token(cached_launch_with_nonce).merge({
            state: oidc_params[:state]
          })
        end
      end

      def authorize_redirect_url
        url = URI.parse(lti_1_3_authorization_url(params: oidc_params))
        url.host = canvas_domain
        url.to_s
      end

      def developer_key
        @developer_key ||= DeveloperKey.find_cached(oidc_params[:client_id].to_i)
      end

      def redirect_uri
        @redirect_uri ||= begin
          requested_redirect_base = oidc_params[:redirect_uri].split('?').first

          unless developer_key.redirect_uris.include? requested_redirect_base
            reject! 'Invalid redirect_uri' and return
          end

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
        reject! 'Invalid lti_message_hint'
      end
    end
  end
end