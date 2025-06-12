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

class AuthenticationProvider::SAML::MetadataRefresher < AuthenticationProvider::ProviderRefresher
  class << self
    def refresh_providers(shard_scope: Shard.current, providers: nil)
      federations = AuthenticationProvider::SAML::Federation.descendants
                                                            .reject { |federation| federation::MDQ }
                                                            .map { |federation| federation::URN }
      providers ||= AuthenticationProvider::SAML.active
                                                .where.not(metadata_uri: [nil, ""] + federations)
                                                .shard(shard_scope)
      super
    end

    private

    def uri_for(provider)
      effective_metadata_uri = AuthenticationProvider::SAML::Federation
                               .descendants
                               .find { |federation| federation::MDQ && provider.metadata_uri == federation::URN }
                               &.metadata_uri(provider.idp_entity_id)

      effective_metadata_uri || super
    end
  end
end
