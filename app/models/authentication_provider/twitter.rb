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

class AuthenticationProvider::Twitter < AuthenticationProvider::Oauth
  include AuthenticationProvider::PluginSettings
  self.plugin = :twitter
  plugin_settings :consumer_key, consumer_secret: :consumer_secret_dec

  def self.recognized_params
    [ :login_attribute, :jit_provisioning ].freeze
  end

  def self.login_attributes
    ['user_id'.freeze, 'screen_name'.freeze].freeze
  end
  validates :login_attribute, inclusion: login_attributes

  def self.recognized_federated_attributes
    [
      'name'.freeze,
      'screen_name'.freeze,
      'time_zone'.freeze,
      'user_id'.freeze,
    ].freeze
  end

  def login_attribute
    super || 'user_id'.freeze
  end

  def unique_id(token)
    token.params[login_attribute.to_sym]
  end

  def provider_attributes(token)
    result = token.params.dup
    if federated_attributes.any? { |(_k, v)| ['name', 'time_zone'].include?(v['attribute']) }
      result.merge!(JSON.parse(token.get('/1.1/account/verify_credentials.json?skip_status=true').body))
    end
    result
  end

  protected

  def consumer_options
    {
      site: 'https://api.twitter.com'.freeze,
      authorize_path: '/oauth/authenticate'.freeze
    }
  end
end
