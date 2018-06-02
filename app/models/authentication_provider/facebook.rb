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

class AuthenticationProvider::Facebook < AuthenticationProvider::Oauth2
  include AuthenticationProvider::PluginSettings

  self.plugin = :facebook
  plugin_settings :app_id, app_secret: :app_secret_dec

  SENSITIVE_PARAMS = [ :app_secret ].freeze

  alias_attribute :app_id, :client_id
  alias_attribute :app_secret, :client_secret

  def client_id
    self.class.globally_configured? ? app_id : super
  end

  def client_secret
    self.class.globally_configured? ? app_secret : super
  end

  def self.recognized_params
    [ :login_attribute, :jit_provisioning ].freeze
  end

  def self.login_attributes
    ['id'.freeze, 'email'.freeze].freeze
  end
  validates :login_attribute, inclusion: login_attributes

  def self.recognized_federated_attributes
    [
      'email'.freeze,
      'first_name'.freeze,
      'id'.freeze,
      'last_name'.freeze,
      'locale'.freeze,
      'name'.freeze,
    ].freeze
  end

  def login_attribute
    super || 'id'.freeze
  end

  def unique_id(token)
    me(token)[login_attribute]
  end

  def provider_attributes(token)
    me(token)
  end

  protected

  def me(token)
    # abusing AccessToken#options as a useful place to cache this response
    token.options[:me] ||= begin
      attributes = ([login_attribute] + federated_attributes.values.map { |v| v['attribute'] }).uniq
      token.get("me?fields=#{attributes.join(',')}").parsed
    end
  end

  def authorize_options
    if login_attribute == 'email' || federated_attributes.any? { |(_k, v)| v['attribute'] == 'email' }
      { scope: 'email'.freeze }.freeze
    else
      {}.freeze
    end
  end

  def client_options
    {
      site: 'https://graph.facebook.com'.freeze,
      authorize_url: 'https://www.facebook.com/dialog/oauth'.freeze,
      token_url: 'oauth/access_token'.freeze
    }
  end
end
