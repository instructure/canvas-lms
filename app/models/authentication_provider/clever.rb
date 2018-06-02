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

class AuthenticationProvider::Clever < AuthenticationProvider::Oauth2
  include AuthenticationProvider::PluginSettings
  self.plugin = :clever
  plugin_settings :client_id, client_secret: :client_secret_dec

  def self.singleton?
    false
  end

  def self.recognized_params
    [ :login_attribute, :district_id, :jit_provisioning ].freeze
  end

  def self.login_attributes
    ['id'.freeze, 'sis_id'.freeze, 'email'.freeze, 'student_number'.freeze, 'teacher_number'.freeze].freeze
  end
  validates :login_attribute, inclusion: login_attributes

  def self.recognized_federated_attributes
    login_attributes
  end

  # Rename db field
  alias_attribute :district_id, :auth_filter

  def login_attribute
    super || 'id'.freeze
  end

  def unique_id(token)
    data = me(token)

    if district_id.present? && data['district'] != district_id
      # didn't make a "nice" exception for this, cause it should never happen.
      # either we got MITM'ed (on the server side), or Clever's docs lied;
      # this check is just an extra precaution
      raise "Non-matching district: #{data['district'].inspect}"
    end
    data[login_attribute]
  end

  def provider_attributes(token)
    me(token)
  end

  protected

  def me(token)
    token.options[:me] ||= token.get("/me").parsed['data']
  end

  def client_options
    {
        site: 'https://api.clever.com'.freeze,
        authorize_url: 'https://clever.com/oauth/authorize',
        token_url: 'https://clever.com/oauth/tokens'.freeze
    }
  end

  def authorize_options
    result = { scope: scope }
    result[:district_id] = district_id if district_id.present?
    result
  end

  def scope
    'read:user_id'
  end

  def token_options
    authorization = Base64.strict_encode64("#{client_id}:#{client_secret}")
    {
      headers: { 'Authorization' => "Basic #{authorization}" }
    }
  end
end
