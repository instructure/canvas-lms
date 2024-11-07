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

# A refresher that refreshes JWKS when there is no discovery document
class AuthenticationProvider::OpenIDConnect::JwksRefresher < AuthenticationProvider::ProviderRefresher
  class << self
    def refresh_providers(shard_scope: Shard.current, providers: nil)
      providers ||= AuthenticationProvider::OpenIDConnect.active
                                                         .shard(shard_scope)
                                                         .select(&:jwks_uri)
      super
    end

    private

    def uri_for(provider)
      provider.jwks_uri
    end

    def assign_metadata(provider, metadata)
      provider.jwks = metadata
    end
  end
end
