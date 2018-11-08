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
      skip_before_action :load_user, only: :authorize_redirect
      skip_before_action :verify_authenticity_token, only: :authorize_redirect

      # Redirect the "authorize" action for the domain specified
      # in the lti_message_hint
      def authorize_redirect
        redirect_to authorize_redirect_url
      end

      def authorize
        render(
          'lti/ims/authentication/authorize.html.erb',
          layout: 'borderless_lti',
          locals: {
            redirect_uri: redirect_uri,
            params: authorization_response_params
          }
        )
      end

      private

      def verifier
        decoded_jwt['verifier']
      end

      def canvas_domain
        decoded_jwt['canvas_domain']
      end

      def authorize_redirect_url
        url = URI.parse(lti_1_3_authorization_url(params: oidc_params))
        url.host = canvas_domain
        url.to_s
      end

      def authorization_response_params
        # TODO if errors exist populate with error params as outlined in
        #      section 3.1.2.6 (Authentication Error Response). Otherwise
        #      populate with ID TOken.
        {}
      end

      def redirect_uri
        @redirect_uri ||= begin
          developer_key = DeveloperKey.find_cached(oidc_params[:client_id].to_i)
          requested_redirect_base = oidc_params[:redirect_uri].split('?').first

          # TODO Verify account binding is on for context (need context first)
          reject! 'Invalid client_id' and return unless developer_key.usable?
          unless developer_key.redirect_uris.include? requested_redirect_base
            reject! 'Invalid redirect_uri' and return
          end

          oidc_params[:redirect_uri]
        end
      end

      def oidc_params
        params.permit(
          :client_id,
          :login_hint,
          :lti_message_hint,
          :nonce,
          :prompt,
          :redirect_uri,
          :response_mode,
          :response_type,
          :scope,
          :state
        )
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