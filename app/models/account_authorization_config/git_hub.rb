#
# Copyright (C) 2015 Instructure, Inc.
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

class AccountAuthorizationConfig::GitHub < AccountAuthorizationConfig::Oauth2
  def self.singleton?
    true
  end

  def self.sti_name
    'github'.freeze
  end

  def self.recognized_params
    if globally_configured?
      [ :auth_type ].freeze
    else
      [ :auth_type, :client_id, :client_secret, :domain ].freeze
    end
  end

  def self.globally_configured?
    Canvas::Plugin.find(:github).enabled?
  end

  # Rename db field
  def domain=(val)
    self.auth_host = val
  end

  def domain
    self.class.globally_configured? ? settings[:domain] : auth_host
  end

  def client_id
    self.class.globally_configured? ? settings[:client_id] : super
  end

  def client_secret
    if self.class.globally_configured?
      settings[:client_secret_dec]
    else
      auth_decrypted_password
    end
  end

  def unique_id(token)
    token.options[:mode] = :query
    token.get('user').parsed['id'].to_s
  end

  protected

  def settings
    Canvas::Plugin.find(:github).settings
  end

  def client_options
    {
        site: domain.present? ? "https://#{domain}/api/v3" : 'https://api.github.com'.freeze,
        authorize_url: "https://#{inferred_domain}/login/oauth/authorize",
        token_url: "https://#{inferred_domain}/login/oauth/access_token"
    }
  end

  def inferred_domain
    domain.presence || 'github.com'.freeze
  end
end
