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

class AuthenticationProvider::LinkedIn < AuthenticationProvider::Oauth2
  include AuthenticationProvider::PluginSettings
  self.plugin = :linked_in
  plugin_settings :client_id, client_secret: :client_secret_dec

  def self.sti_name
    'linkedin'.freeze
  end

  def self.recognized_params
    [ :login_attribute, :jit_provisioning ].freeze
  end

  def self.login_attributes
    ['id'.freeze, 'emailAddress'.freeze].freeze
  end
  validates :login_attribute, inclusion: login_attributes

  def self.recognized_federated_attributes
    [
      'emailAddress'.freeze,
      'firstName'.freeze,
      'id'.freeze,
      'formattedName'.freeze,
      'lastName'.freeze,
    ].freeze
  end

  def login_attribute
    super || 'id'.freeze
  end

  def unique_id(token)
    person(token)[login_attribute]
  end

  def provider_attributes(token)
    person(token)
  end

  protected

  def person(token)
    token.options[:person] ||= begin
      attributes = [login_attribute] + federated_attributes.values.map { |v| v['attribute'] }
      token.get("/v1/people/~:(#{attributes.uniq.join(',')})?format=json").parsed
    end
  end

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
    if login_attribute == 'emailAddress'.freeze ||
        federated_attributes.any? { |(_k, v)| v['attribute'] == 'emailAddress' }
      'r_basicprofile r_emailaddress'.freeze
    else
      'r_basicprofile'.freeze
    end
  end
end
