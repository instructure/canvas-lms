#
# Copyright (C) 2015 - present Instructure, Inc.
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

class AuthenticationProvider::SamlIdpDiscovery < AuthenticationProvider::Delegated
  class << self
    def enabled?(_account = nil)
      AuthenticationProvider::SAML.enabled?
    end

    def recognized_params
      [ :discovery_service_url ].freeze
    end

    def display_name
      'SAML IdP Discovery Service'
    end

    def sti_name
      'saml_idp_discovery'
    end
  end

  alias_attribute :discovery_service_url, :log_in_url
end
