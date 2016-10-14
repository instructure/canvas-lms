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

class AccountAuthorizationConfig::Google < AccountAuthorizationConfig::OpenIDConnect
  include AccountAuthorizationConfig::PluginSettings
  self.plugin = :google_drive
  plugin_settings :client_id, client_secret: :client_secret_dec

  def self.singleton?
    false
  end

  def self.recognized_params
    [ :login_attribute, :jit_provisioning, :hosted_domain ].freeze
  end

  # Rename db field
  def hosted_domain=(val)
    self.auth_filter = val.presence
  end

  def hosted_domain
    auth_filter
  end

  def self.login_attributes
    ['sub'.freeze, 'email'.freeze].freeze
  end
  validates :login_attribute, inclusion: login_attributes

  def self.recognized_federated_attributes
    [
      'email'.freeze,
      'family_name'.freeze,
      'given_name'.freeze,
      'locale'.freeze,
      'name'.freeze,
      'sub'.freeze,
    ].freeze
  end

  def unique_id(token)
    id_token = claims(token)
    if hosted_domain && id_token['hd'] != hosted_domain
      # didn't make a "nice" exception for this, cause it should never happen.
      # either we got MITM'ed (on the server side), or Google's docs lied;
      # this check is just an extra precaution
      raise "Non-matching hosted domain: #{id_token['hd'].inspect}"
    end
    super
  end

  protected

  def userinfo_endpoint
    "https://www.googleapis.com/oauth2/v3/userinfo".freeze
  end

  def authorize_options
    result = { scope: scope_for_options }
    result[:hd] = hosted_domain if hosted_domain
    result
  end

  def scope
    scopes = []
    scopes << 'email' if login_attribute == 'email'.freeze ||
        hosted_domain ||
        federated_attributes.any? { |(_k, v)| v['attribute'] == 'email' }
    scopes << 'profile' if federated_attributes.any? { |(_k, v)| v['attribute'] == 'name' }
    scopes.join(' ')
  end

  def authorize_url
    'https://accounts.google.com/o/oauth2/auth'.freeze
  end

  def token_url
    'https://accounts.google.com/o/oauth2/token'.freeze
  end
end
