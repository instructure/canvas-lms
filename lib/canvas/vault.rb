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

require 'vault'

module Canvas::Vault
  class << self
    CACHE_KEY_PREFIX = 'vault/'.freeze

    def read(path)
      cached_val = LocalCache.fetch(CACHE_KEY_PREFIX + path)
      return cached_val unless cached_val.nil?

      begin
        vault_resp = api_client.logical.read(path)
        return nil if vault_resp.nil?

        token_ttl = vault_resp.lease_duration || vault_resp.data[:ttl] || 10.minutes
        cache_ttl = token_ttl / 2
        LocalCache.write(CACHE_KEY_PREFIX + path, vault_resp.data, expires_in: cache_ttl)

        return vault_resp.data
      rescue => exception
        Canvas::Errors.capture_exception(:vault, exception)
        return LocalCache.fetch_without_expiration(CACHE_KEY_PREFIX + path)
      end
    end

    def api_client
      Vault::Client.new(address: addr, token: token)
    end

    def kv_mount
      config[:kv_mount]
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

    def config
      ConfigFile.load('vault').try(:symbolize_keys) || {}
    end
  end
end