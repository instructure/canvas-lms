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

module Canvas::OAuth
  CUSTOM_CLAIM_KEY = "canvas.instructure.com"

  class ClientCredentialsProvider < Provider
    def initialize(client_id, host, scopes = nil, protocol = "http://")
      super(client_id, nil, scopes || [])
      @expected_aud = Rails.application.routes.url_helpers.oauth2_token_url(
        host: host,
        protocol: protocol
      )
    end

    def generate_token
      claims, scopes, ttl = generate_claims
      {
        access_token: key.issue_token(claims),
        token_type: "Bearer",
        expires_in: ttl.seconds,
        scope: scopes
      }
    end

    def valid?
      raise "Abstract Method"
    end

    def error_message
      raise "Abstract Method"
    end

    private

    def allowed_scopes
      @allowed_scopes ||= @scopes.join(" ")
    end

    def generate_claims
      scopes = allowed_scopes
      timestamp = Time.zone.now.to_i
      ttl = Setting.get("oauth2_jwt_exp_in_seconds", 1.hour.to_s).to_i
      claims = {
        iss: Canvas::Security.config["lti_iss"],
        sub: @client_id,
        aud: @expected_aud,
        iat: timestamp,
        exp: timestamp + ttl,
        jti: SecureRandom.uuid,
        scopes: scopes
      }
      if key.account_id
        # if developer key is account scoped, add namespaced custom claim about
        # account id
        claims[CUSTOM_CLAIM_KEY] = { "account_uuid" => key.account.uuid }
      end
      [claims, scopes, ttl]
    end
  end
end
