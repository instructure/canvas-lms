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
  include AccountAuthorizationConfig::PluginSettings
  self.plugin = :linked_in
  plugin_settings :client_id, client_secret: :client_secret_dec

  def self.sti_name
    'linkedin'.freeze
  end

  def self.recognized_params
    [ :login_attribute ].freeze
  end

  def self.login_attributes
    ['id'.freeze, 'emailAddress'.freeze].freeze
  end
  validates :login_attribute, inclusion: login_attributes

  def login_attribute
    super || 'id'.freeze
  end

  def login_button?
    true
  end

  def unique_id(token)
    token.get("/v1/people/~:(#{login_attribute})?format=json").parsed[login_attribute]
  end

  protected

  def client_options
    {
      site: 'https://api.linkedin.com'.freeze,
      authorize_url: 'https://www.linkedin.com/uas/oauth2/authorization',
      token_url: 'https://www.linkedin.com/uas/oauth2/accessToken'
    }
  end

  def authorize_options
    { scope: scope }
  end

  def scope
    if login_attribute == 'emailAddress'.freeze
      'r_basicprofile r_emailaddress'.freeze
    else
      'r_basicprofile'.freeze
    end
  end
end
