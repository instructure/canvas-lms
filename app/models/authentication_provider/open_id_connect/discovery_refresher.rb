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

class AuthenticationProvider::OpenIDConnect::DiscoveryRefresher < AuthenticationProvider::ProviderRefresher
  class << self
    def refresh_providers(shard_scope: Shard.current, providers: nil)
      # _only_ refresh OpenID Connect providers; any sub-classes likely need the same metadata for
      # all instances, so they should inherit from this class and implement caching
      providers ||= AuthenticationProvider.active
                                          .where.not(metadata_uri: [nil, ""])
                                          .where(auth_type: "openid_connect")
                                          .shard(shard_scope)
      super
    end
  end
end
