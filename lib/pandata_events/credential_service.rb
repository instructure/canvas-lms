# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

module PandataEvents
  # Represents a PandataEvents app key/secret pair, which is used to authenticate
  # and partition events sent to the service.
  # Provides JWTs for service auth and signed properties
  # (https://gerrit.instructure.com/plugins/gitiles/PandataEvents/+/refs/heads/master/#signed-properties),
  # which allows properties to be consistent and immutable when sent from a client.
  #
  # Credentials are stored in Vault (an example structure is found in config/vault_contents.yml.example),
  # and are referenced by either the PandataEvents app key or the storage prefix ("canvas" -> "canvas_key", "canvas_secret").
  class CredentialService
    attr_accessor :app_key, :secret, :alg

    def initialize(app_key: nil, prefix: nil, valid_prefixes: nil)
      raise Errors::InvalidAppKey, "must provide either app_key or prefix" unless app_key.present? || prefix.present?
      raise Errors::InvalidAppKey, "must provide only one of app_key or prefix" if app_key.present? && prefix.present?

      app_key = app_key.to_s
      prefix = prefix.to_s
      creds = PandataEvents.credentials
      all_prefixes = creds.keys.select { |k| k.ends_with?("_key") }.map { |k| k.gsub(/_key$/, "") }
      valid_prefixes ||= all_prefixes

      if app_key.present?
        prefix = valid_prefixes.find { |p| creds["#{p}_key"] == app_key }
      end
      raise Errors::InvalidAppKey unless prefix && valid_prefixes.include?(prefix)

      @app_key = creds["#{prefix}_key"]
      @secret = creds["#{prefix}_secret"]
      @alg = creds["#{prefix}_secret_alg"] || :ES512
    end

    def token(body, expires_at: nil)
      private_key = if alg == :ES512
                      OpenSSL::PKey::EC.new(Base64.decode64(secret))
                    else
                      secret # for HS256/HS512
                    end

      Canvas::Security.create_jwt(body, expires_at, private_key, alg)
    end

    def auth_token(sub, expires_at: nil, cache: true)
      if cache
        cache_key = "pandata_events:auth_token:#{app_key}:#{sub}:1"
        cached_token = Canvas.redis.get(cache_key)
        return cached_token if cached_token
      end

      auth_body = {
        iss: app_key,
        aud: "PANDATA",
        sub:
      }.compact

      # these tokens should always expire, so don't allow nil here
      expires_at ||= 1.day.from_now
      auth_token = token(auth_body, expires_at:)

      if cache
        # expire the cached token 5 minutes before it actually expires
        ttl = expires_at.to_i - Time.now.to_i - 5.minutes
        Canvas.redis.setex(cache_key, ttl, auth_token)
      end

      auth_token
    end
  end
end
