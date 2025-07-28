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

module DeveloperKeys
  module AccessVerifier
    TTL_MINUTES = 5

    def self.generate(claims)
      return {} unless claims[:developer_key] && claims[:authorization]

      developer_key = claims[:developer_key]
      root_account = claims[:root_account]

      jwt_claims = {
        developer_key_id: developer_key.global_id.to_s,
        skip_redirect_for_inline_content: true
      }
      jwt_claims[:attachment_id] = claims[:authorization][:attachment].global_id.to_s
      jwt_claims[:permission] = claims[:authorization][:permission]
      jwt_claims[:root_account_id] = root_account.global_id.to_s if root_account
      jwt_claims.merge!(claims.slice(:oauth_host, :return_url, :fallback_url))

      expires = TTL_MINUTES.minutes.from_now
      key = nil # use default key
      {
        sf_verifier: Canvas::Security.create_jwt(jwt_claims, expires, key, :HS512)
      }
    end
  end
end
