#
# Copyright (C) 2016 - present Instructure, Inc.
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

class AuthenticationProvider::Microsoft < AuthenticationProvider::OpenIDConnect
  include AuthenticationProvider::PluginSettings
  self.plugin = :microsoft
  plugin_settings :application_id, application_secret: :application_secret_dec

  SENSITIVE_PARAMS = [ :application_secret ].freeze

  def self.singleton?
    false
  end

  # Rename db fields
  alias_attribute :application_id, :client_id
  alias_attribute :application_secret, :client_secret

  def client_id
    self.class.globally_configured? ? application_id : super
  end

  def client_secret
    self.class.globally_configured? ? application_secret : super
  end

  def tenant=(val)
    self.auth_filter = val
  end

  def tenant
    auth_filter
  end

  def self.recognized_params
    [:tenant, :login_attribute, :jit_provisioning].freeze
  end

  def self.login_attributes
    ['sub'.freeze, 'email'.freeze, 'oid'.freeze, 'preferred_username'.freeze].freeze
  end
  validates :login_attribute, inclusion: login_attributes

  def self.recognized_federated_attributes
    [
      'email'.freeze,
      'name'.freeze,
      'preferred_username'.freeze,
      'oid'.freeze,
      'sub'.freeze,
    ].freeze
  end

  def login_attribute
    super || 'id'.freeze
  end

  protected

  def authorize_url
    "https://login.microsoftonline.com/#{tenant_value}/oauth2/v2.0/authorize"
  end

  def token_url
    "https://login.microsoftonline.com/#{tenant_value}/oauth2/v2.0/token"
  end

  def scope
    result = []
    requested_attributes = [login_attribute] + federated_attributes.values.map { |v| v['attribute'] }
    result << 'profile' unless (requested_attributes & ['name', 'oid', 'preferred_username']).empty?
    result << 'email' if requested_attributes.include?('email')
    result.join(' ')
  end

  def tenant_value
    tenant.presence || 'common'
  end

end
