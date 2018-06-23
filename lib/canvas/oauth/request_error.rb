#
# Copyright (C) 2015 - present Instructure, Inc.
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

module Canvas::Oauth
  class RequestError < StandardError
    ERROR_MAP = {
      invalid_client_id: {
        error: :invalid_client,
        error_description: "unknown client",
        http_status: 401
      }.freeze,

      invalid_client_secret: {
        error: :invalid_client,
        error_description: "invalid client",
        http_status: 401
      }.freeze,

      invalid_redirect: {
        error: :invalid_request,
        error_description: "redirect_uri does not match client settings"
      }.freeze,

      invalid_refresh_token: {
        error: :invalid_request,
        error_description: "refresh_token not found"
      }.freeze,

      invalid_authorization_code: {
        error: :invalid_grant,
        error_description: "authorization_code not found"
      }.freeze,

      incorrect_client: {
        error: :invalid_grant,
        error_description: "incorrect client"
      }.freeze,

      invalid_scope: {
        error: :invalid_scope,
        error_description: 'A requested scope is invalid, unknown, malformed, or exceeds the scope granted by the resource owner.'
      }.freeze,

      authorization_code_not_supplied: {
        error: :invalid_request,
        error_description: "You must provide the code parameter when using the authorization_code grant type"
      }.freeze,

      refresh_token_not_supplied: {
        error: :invalid_request,
        error_description: "You must provide the refresh_token parameter when using the refresh_token grant type"
      }.freeze,

      unsupported_grant_type: {
        error: :unsupported_grant_type,
        error_description: "The grant_type you requested is not currently supported"
      }.freeze
    }.freeze

    def initialize(message)
      @message = message
    end

    def as_json
      {
        error: error_map[:error],
        error_description: error_map[:error_description]
      }
    end

    def to_render_data
      {
        status: http_status,
        json: as_json
      }
    end

    def http_status
      error_map[:http_status] || 400
    end

    private

    def error_map
      ERROR_MAP[@message]
    end
  end
end
