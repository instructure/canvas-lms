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

class AccountAuthorizationConfig::Twitter < AccountAuthorizationConfig::Oauth
  include AccountAuthorizationConfig::PluginSettings
  self.plugin = :twitter
  plugin_settings :consumer_key, consumer_secret: :consumer_secret_dec

  def login_button?
    true
  end

  def self.recognized_params
    [ :login_attribute ].freeze
  end

  def self.login_attributes
    ['user_id'.freeze, 'screen_name'.freeze].freeze
  end
  validates :login_attribute, inclusion: login_attributes

  def login_attribute
    super || 'user_id'.freeze
  end

  def unique_id(token)
    token.params[login_attribute.to_sym]
  end

  protected

  def consumer_options
    {
      site: 'https://api.twitter.com'.freeze,
      authorize_path: '/oauth/authenticate'.freeze
    }
  end
end
