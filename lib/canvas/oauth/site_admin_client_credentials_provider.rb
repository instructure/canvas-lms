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
  # SiteAdmin-only Provider that performs no verification checks
  # and gives a token back without question
  # warning: make sure whatever calls this is behind a require_site_admin
  # check, or anyone can get an access token for any tool
  class SiteAdminClientCredentialsProvider < ClientCredentialsProvider
    def initialize(client_id, host, scopes, user, protocol = "https://")
      @user = user
      super(client_id, host, scopes:, protocol:)
    end

    def valid?
      true
    end

    def error_message
      ""
    end

    def generate_token
      claims, scopes, ttl = generate_claims

      claims[CUSTOM_CLAIM_KEY] ||= {}
      claims[CUSTOM_CLAIM_KEY]["token_generated_for"] = "site_admin"
      claims[CUSTOM_CLAIM_KEY]["token_generated_by"] = @user.global_id

      {
        access_token: key.issue_token(claims),
        token_type: "Bearer",
        expires_in: ttl.seconds,
        scope: scopes
      }
    end
  end
end
