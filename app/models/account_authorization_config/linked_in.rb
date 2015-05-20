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

class AccountAuthorizationConfig::LinkedIn < AccountAuthorizationConfig::Oauth2
  def self.singleton?
    true
  end

  def self.sti_name
    'linkedin'
  end

  def self.recognized_params
    if globally_configured?
      [].freeze
    else
      [ :client_id, :client_secret ].freeze
    end
  end

  def self.globally_configured?
    Canvas::Plugin.find(:linked_in).enabled?
  end

  def client_id
    self.class.globally_configured? ? settings[:client_id] : super
  end

  def client_secret
    if self.class.globally_configured?
      settings[:client_secret_dec]
    else
      super
    end
  end

  def unique_id(token)
    token.get('/v1/people/~:(id)?format=json').parsed['id']
  end

  protected

  def settings
    Canvas::Plugin.find(:linked_in).settings
  end

  def client_options
    {
      site: 'https://api.linkedin.com'.freeze,
      authorize_url: 'https://www.linkedin.com/uas/oauth2/authorization',
      token_url: 'https://www.linkedin.com/uas/oauth2/accessToken'
    }
  end

  def authorize_options
    { scope: 'r_basicprofile' }
  end
end
