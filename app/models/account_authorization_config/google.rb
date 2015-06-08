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

  def login_button?
    true
  end

  def self.recognized_params
    [ :login_attribute ].freeze
  end

  def self.login_attributes
    ['sub'.freeze, 'email'.freeze].freeze
  end
  validates :login_attribute, inclusion: login_attributes

  protected

  def scope
    'email'.freeze if login_attribute == 'email'.freeze
  end

  def authorize_url
    'https://accounts.google.com/o/oauth2/auth'.freeze
  end

  def token_url
    'https://accounts.google.com/o/oauth2/token'.freeze
  end
end
