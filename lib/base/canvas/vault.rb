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
  class MissingVaultSecret < StandardError; end

  class << self
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
      Canvas::Errors.capture_exception(:vault, e)
      stale_value = LocalCache.fetch_without_expiration(CACHE_KEY_PREFIX + path)
      return stale_value if stale_value.present?

      # if we can't serve any stale value, we're better erroring than handing back nil
      raise
    end

    def api_client
      # Default to flat file if vault is unconfigured
      return Canvas::Vault::FileClient.get_client if addr.nil? || addr == "file"

      Vault::Client.new(address: addr, token:)
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
      elsif config[:addr]
        config[:addr]
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
  end
end
