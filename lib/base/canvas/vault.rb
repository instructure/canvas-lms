# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require "vault"

module Canvas::Vault
  CACHE_KEY_PREFIX = "vault/"
  TOKEN_REFRESH_BUFFER = 300 # Refresh 5 minutes before expiry

  class MissingVaultSecret < StandardError; end
  class VaultAuthError < StandardError; end

  class << self
    def cached?(path)
      LocalCache.fetch_without_expiration(CACHE_KEY_PREFIX + path).present?
    end

    def read(path, required: true, cache: true)
      Rails.logger.info("Reading #{path} from vault")
      unless cache
        vault_resp = api_client.logical.read(path)
        raise(MissingVaultSecret, "nil credentials found for #{path}") if required && vault_resp.nil?

        return vault_resp&.data
      end

      # we're going to override this anyway, just want it to use the fetch path.
      default_expiry = 30.minutes
      default_race_condition_ttl = 60.seconds
      cache_key = CACHE_KEY_PREFIX + path
      fetched_lease_value = nil
      cached_data = LocalCache.fetch(cache_key, expires_in: default_expiry, race_condition_ttl: default_race_condition_ttl) do
        vault_resp = api_client.logical.read(path)
        raise(MissingVaultSecret, "nil credentials found for #{path}") if required && vault_resp.nil?

        fetched_lease_value = vault_resp&.lease_duration
        fetched_lease_value = vault_resp&.data&.[](:ttl) unless fetched_lease_value&.positive?
        fetched_lease_value = 10.minutes unless fetched_lease_value&.positive?
        vault_resp&.data
      end
      unless fetched_lease_value.nil?
        # we actually talked to vault and got a new record, let's update the expiration information
        # so actually be sensitive to the data in the lease
        cache_ttl = fetched_lease_value / 2
        LocalCache.write(cache_key, cached_data, expires_in: cache_ttl)
      end
      cached_data
    rescue => e
      # autoloading probably isn't set up yet; load Canvas::Errors explicitly so that we
      # don't mask the original error
      require_dependency "canvas/errors"
      Canvas::Errors.capture_exception(:vault, e)
      stale_value = LocalCache.fetch_without_expiration(CACHE_KEY_PREFIX + path)
      return stale_value if stale_value.present?

      # if we can't serve any stale value, we're better erroring than handing back nil
      raise
    end

    def api_client
      # Default to flat file if vault is unconfigured
      return Canvas::Vault::FileClient.get_client if addr.nil? || addr == "file"

      if iam_auth_enabled?
        Vault::Client.new(address: addr, token: iam_token)
      else
        Vault::Client.new(address: addr, token:)
      end
    end

    def kv_mount
      config[:kv_mount] || "app-canvas"
    end

    def config
      ConfigFile.load("vault").try(:symbolize_keys) || {}
    end

    private

    def addr
      if config[:addr_path]
        File.read(config[:addr_path]).chomp
      elsif config.key?(:addr)
        config[:addr]
      elsif ENV["VAULT_ADDR"].present?
        ENV["VAULT_ADDR"]
      end
    end

    def token
      # We deliberately want to read this token every time, as it may be refreshed in the background
      if config[:token_path]
        File.read(config[:token_path]).chomp
      elsif config[:token]
        config[:token]
      end
    end

    def iam_auth_enabled?
      ActiveModel::Type::Boolean.new.cast(ENV["VAULT_IAM_AUTH_ENABLED"])
    end

    def iam_auth_role
      ENV["VAULT_AWS_AUTH_ROLE"]
    end

    def iam_auth_path
      ENV["VAULT_AWS_AUTH_PATH"] || "aws"
    end

    def iam_auth_header_value
      ENV["VAULT_AWS_AUTH_HEADER_VALUE"]
    end

    def iam_token
      return @iam_token_cache[:token] if @iam_token_cache && iam_token_valid?(@iam_token_cache)

      authenticate_with_iam
    end

    def authenticate_with_iam
      raise VaultAuthError, "VAULT_AWS_AUTH_ROLE required for IAM authentication" if iam_auth_role.blank?

      Rails.logger.info("Vault: Authenticating with AWS IAM auth")
      client = Vault::Client.new(address: addr)

      credentials_provider = Aws::CredentialProviderChain.new.resolve

      secret = client.auth.aws_iam(
        iam_auth_role,
        credentials_provider,
        iam_auth_header_value.presence,
        "https://sts.amazonaws.com",
        iam_auth_path
      )

      # Cache token in memory (not in LocalCache which may persist to Redis)
      @iam_token_cache = {
        token: secret.auth.client_token,
        lease_duration: secret.auth.lease_duration,
        obtained_at: Time.now.to_i
      }

      Rails.logger.info("Vault: IAM auth successful, token TTL: #{secret.auth.lease_duration}s")
      secret.auth.client_token
    rescue Vault::HTTPError => e
      Canvas::Errors.capture_exception(:vault_iam_auth, e)
      Rails.logger.error("Vault: IAM authentication failed: #{e.message}")

      # Use stale in-memory token as fallback (automatic with instance variable)
      if @iam_token_cache&.[](:token)
        Rails.logger.warn("Vault: Using expired cached token due to auth failure")
        return @iam_token_cache[:token]
      end

      raise VaultAuthError, "Failed to authenticate to Vault with IAM: #{e.message}"
    end

    def iam_token_valid?(cached)
      expiry = cached[:obtained_at] + cached[:lease_duration]
      Time.now.to_i < (expiry - TOKEN_REFRESH_BUFFER)
    end
  end
end
