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

module AccessVerifier
  TTL_MINUTES = 5

  class InvalidVerifier < RuntimeError
  end

  class JtiReused < RuntimeError
  end

  def self.generate(claims)
    return {} unless required_claims_present?(claims)

    jwt_claims = {}

    if (user = claims[:user])
      real_user = claims[:real_user] if claims[:real_user] && claims[:real_user] != claims[:user]
      jwt_claims[:user_id] = user.global_id.to_s
      jwt_claims[:real_user_id] = real_user.global_id.to_s if real_user
    end

    if (authorization = claims[:authorization])
      jwt_claims[:attachment_id] = authorization[:attachment].global_id.to_s
      jwt_claims[:permission] = authorization[:permission]
    end

    if (root_account = claims[:root_account])
      jwt_claims[:root_account_id] = root_account.global_id.to_s if root_account
    end

    if (developer_key = claims[:developer_key])
      jwt_claims[:developer_key_id] = developer_key.global_id.to_s
      if claims[:user].blank? # only for dev key verifier that is used in S2S communication
        jwt_claims[:skip_redirect_for_inline_content] = true
      end
    end

    jwt_claims.merge!(claims.slice(:oauth_host, :return_url, :fallback_url))

    expires = TTL_MINUTES.minutes.from_now
    jwt_claims[:jti] = SecureRandom.uuid if Account.site_admin.feature_enabled?(:safe_files_jti)
    Rails.cache.write("sf_verifier:#{jwt_claims[:jti]}", true, expires_at: expires)
    key = nil # use default key
    { sf_verifier: Canvas::Security.create_jwt(jwt_claims, expires, key, :HS512) }
  end

  def self.required_claims_present?(claims)
    claims[:user].present? || ((claims.dig(:authorization, :attachment) || claims[:attachment_id]).present? && (claims.dig(:authorization, :permission) || claims[:permission]).present?)
  end

  def self.validate(params)
    return {} if params[:sf_verifier].blank?

    claims = Canvas::Security.decode_jwt(params[:sf_verifier])
    raise JtiReused if claims[:jti].present? && !Rails.cache.delete("sf_verifier:#{claims[:jti]}")

    user, real_user = user_access(claims)
    raise InvalidVerifier unless (user && real_user) || required_claims_present?(claims)

    if claims[:attachment_id].present?
      attachment_id = params[:attachment_id] || params[:file_id] || params[:id]
      raise InvalidVerifier unless Shard.global_id_for(claims[:attachment_id]) == Shard.global_id_for(attachment_id)
    end

    if claims[:developer_key_id].present?
      developer_key = DeveloperKey.find_cached(claims[:developer_key_id])
      raise InvalidVerifier unless developer_key
    end

    if claims[:root_account_id].present?
      root_account = Account.find_cached(claims[:root_account_id])
      raise InvalidVerifier unless root_account
    end

    {
      user:,
      real_user:,
      developer_key:,
      root_account:,
      oauth_host: claims[:oauth_host],
      return_url: claims[:return_url],
      fallback_url: claims[:fallback_url],
      attachment_id: claims[:attachment_id],
      permission: claims[:permission],
    }.with_indifferent_access
  rescue Canvas::Security::InvalidToken
    raise InvalidVerifier
  end

  def self.user_access(claims)
    return if claims[:user_id].blank?

    real_user = user = User.find_by(id: claims[:user_id])
    real_user = User.find_by(id: claims[:real_user_id]) if claims[:real_user_id].present?
    raise InvalidVerifier unless user && real_user

    [user, real_user]
  end

  def self.developer_key_claims?(claims)
    claims[:developer_key_id].present? && claims[:attachment_id].present? && claims[:permission].present?
  end
end
