# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

require "saml2"

class AuthenticationProvider::SAML::MetadataRefresher
  class << self
    def refresh_providers(shard_scope: Shard.current, providers: nil)
      federations = AuthenticationProvider::SAML::Federation.descendants.map { |federation| federation::URN }
      providers ||= AuthenticationProvider::SAML.active
                                                .where.not(metadata_uri: [nil, ""] + federations)
                                                .shard(shard_scope)

      providers.each do |provider|
        new_data = refresh_if_necessary(provider.global_id, provider.metadata_uri)
        next unless new_data

        provider.populate_from_metadata_xml(new_data)
        provider.save! if provider.changed?
      rescue => e
        level = (e.is_a?(Net::HTTPClientException) && e.response.code.to_i == 404) ? :warn : :error
        ::Canvas::Errors.capture(e, { tags: { type: "saml_metadata_refresh", auth_provider: provider.global_id } }, level)
      end
    end

    protected

    # returns the new data if it changed, or false if it has not
    def refresh_if_necessary(provider_key, endpoint, force_fetch: false)
      if !force_fetch && Canvas.redis_enabled?
        etag = Canvas.redis.get("saml_#{provider_key}_etag")
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
          Canvas.redis.set("saml_#{provider_key}_etag", response["ETag"])
        end
        return response.body
      end
    end
  end
end
