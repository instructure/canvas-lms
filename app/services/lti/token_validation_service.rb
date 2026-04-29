# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
  class TokenValidationService
    class << self
      def verify_access_token(request)
        if (e = Lti::IMS::AdvantageAccessTokenRequestHelper.token_error(request))
          { error: e.api_message, status: e.status_code }
        elsif !access_token_from_request(request)
          { error: "Missing access token", status: :unauthorized }
        else
          { success: true }
        end
      end

      def verify_developer_key(request)
        token = access_token_from_request(request)
        return { error: "No access token", status: :unauthorized } unless token

        dev_key = developer_key_from_token(token)

        unless dev_key&.active?
          return { error: "Unknown or inactive Developer Key", status: :unauthorized }
        end

        { success: true, developer_key: dev_key }
      end

      def verify_scopes(request, scopes_matcher)
        token = access_token_from_request(request)
        return { error: "No access token", status: :unauthorized } unless token

        token_scopes = access_token_scopes_from_token(token)
        unless token_scopes.present? && scopes_matcher.call(token_scopes)
          return { error: "Insufficient permissions", status: :unauthorized }
        end

        { success: true, scopes: token_scopes }
      end

      def verify_developer_key_access_token_and_scopes(request, scopes_matcher)
        # Verify access token
        token_result = verify_access_token(request)
        return token_result unless token_result[:success]

        # Verify developer key
        dev_key_result = verify_developer_key(request)
        return dev_key_result unless dev_key_result[:success]

        # Verify scopes
        scopes_result = verify_scopes(request, scopes_matcher)
        return scopes_result unless scopes_result[:success]

        {
          success: true,
          developer_key: dev_key_result[:developer_key],
          scopes: scopes_result[:scopes]
        }
      end

      private

      def access_token_from_request(request)
        Lti::IMS::AdvantageAccessTokenRequestHelper.token(request)
      end

      def access_token_scopes_from_token(token)
        token&.claim("scopes")&.split.presence || []
      end

      def developer_key_from_token(token)
        return nil unless token

        DeveloperKey.find_cached(token.client_id)
      rescue ActiveRecord::RecordNotFound
        nil
      end
    end
  end
end
