# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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
#

class AuthenticationProvider::ProviderRefresher
  class << self
    def refresh_providers(providers:, shard_scope: Shard.current)
      providers.each do |provider|
        new_data = refresh_if_necessary(provider.global_id, uri_for(provider))
        next unless new_data

        assign_metadata(provider, new_data)
        provider.save! if provider.changed?
      rescue => e
        level = (e.is_a?(Net::HTTPClientException) && e.response.code.to_i == 404) ? :warn : :error
        ::Canvas::Errors.capture(e, { tags: { type: "auth_provider_refresh", auth_provider: provider.global_id } }, level)
      end
    end

    private

    def uri_for(provider)
      provider.metadata_uri
    end

    def assign_metadata(provider, metadata)
      provider.metadata = metadata
    end

    # returns the new data if it changed, or false if it has not
    def refresh_if_necessary(_provider_key, endpoint, force_fetch: false)
      etag_key = "auth_provider_refresh_#{Digest::MD5.hexdigest(endpoint)}_etag"
      if !force_fetch && Canvas.redis_enabled?
        etag = Canvas.redis.get(etag_key)
      end

      headers = {}
      headers["If-None-Match"] = etag if etag
      CanvasHttp.get(endpoint, headers) do |response|
        if response.is_a?(Net::HTTPNotModified)
          return false
        end

        # raise on non-success
        response.value
        # store new data
        if Canvas.redis_enabled? && response["ETag"]
          Canvas.redis.set(etag_key, response["ETag"])
        end
        return response.body
      end
    end
  end
end
