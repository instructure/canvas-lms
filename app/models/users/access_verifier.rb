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

require "openssl"

module Users
  module AccessVerifier
    TTL_MINUTES = 5

    class InvalidVerifier < RuntimeError
    end

    def self.generate(claims)
      return {} unless claims[:user]

      user = claims[:user]
      real_user = claims[:real_user] if claims[:real_user] && claims[:real_user] != claims[:user]
      developer_key = claims[:developer_key]
      root_account = claims[:root_account]

      jwt_claims = { user_id: user.global_id.to_s }
      if (authorization = claims[:authorization])
        jwt_claims[:attachment_id] = authorization[:attachment].global_id.to_s
        jwt_claims[:permission] = authorization[:permission]
      end
      jwt_claims[:real_user_id] = real_user.global_id.to_s if real_user
      jwt_claims[:developer_key_id] = developer_key.global_id.to_s if developer_key
      jwt_claims[:root_account_id] = root_account.global_id.to_s if root_account
      jwt_claims.merge!(claims.slice(:oauth_host, :return_url, :fallback_url))

      expires = TTL_MINUTES.minutes.from_now
      key = nil # use default key
      { sf_verifier: Canvas::Security.create_jwt(jwt_claims, expires, key, :HS512) }
    end

    def self.validate(fields)
      return {} if fields[:sf_verifier].blank?

      claims = Canvas::Security.decode_jwt(fields[:sf_verifier])

      if claims[:attachment_id].present?
        attachment_id = fields[:attachment_id] || fields[:file_id] || fields[:id]
        verifier_attachment = Attachment.find_by(id: claims[:attachment_id])
        raise InvalidVerifier unless attachment_id == verifier_attachment&.id&.to_s ||
                                     attachment_id == verifier_attachment&.global_id&.to_s ||
                                     (verifier_attachment&.global_id && attachment_id == Shard.short_id_for(verifier_attachment.global_id))
      end

      real_user = user = User.where(id: claims[:user_id]).first
      real_user = User.where(id: claims[:real_user_id]).first if claims[:real_user_id].present?
      raise InvalidVerifier unless user && real_user

      if claims[:developer_key_id].present?
        developer_key = DeveloperKey.find_cached(claims[:developer_key_id])
        raise InvalidVerifier unless developer_key
      end

      if claims[:root_account_id].present?
        root_account = Account.find_cached(claims[:root_account_id])
        raise InvalidVerifier unless root_account
      end

      oauth_host = claims[:oauth_host]
      return_url = claims[:return_url]

      {
        user:,
        real_user:,
        developer_key:,
        root_account:,
        oauth_host:,
        return_url:
      }
    rescue Canvas::Security::InvalidToken
      raise InvalidVerifier
    end
  end
end
