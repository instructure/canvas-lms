# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

# this isn't technically OpenID Connect, but it's close
class AuthenticationProvider::Apple < AuthenticationProvider::OpenIDConnect
  include AuthenticationProvider::PluginSettings
  self.plugin = :apple
  plugin_settings :client_id, client_secret: :client_secret_dec

  SENSITIVE_PARAMS = [ :client_secret ].freeze

  def self.display_name
    'Sign in with Apple'
  end

  def self.login_message
    display_name
  end

  def self.sti_name
    'apple'
  end

  def self.singleton?
    true
  end

  def self.login_attributes
    ['sub'.freeze, 'email'.freeze].freeze
  end
  validates :login_attribute, inclusion: login_attributes

  def self.recognized_federated_attributes
    [
      'email'.freeze,
      'firstName'.freeze,
      'lastName'.freeze,
      'sub'.freeze,
    ].freeze
  end

  def get_token(_code, _redirect_uri, params)
    jwt_string = params['id_token']
    debug_set(:id_token, jwt_string) if instance_debugging
    id_token = JSON::JWT.decode(jwt_string, apple_public_keys)
    unless
      id_token[:iss] == 'https://appleid.apple.com' &&
      id_token[:aud] == client_id &&
      id_token[:sub].present? &&
      id_token[:exp] > Time.now.to_i
      Rails.logger.warn("Failed to decode Sign in with Apple id_token: #{jwt_string.inspect}")
      raise Canvas::Security::InvalidToken
    end

    user = JSON.parse(params[:user]) if params[:user]
    id_token.merge!(user['name'].slice('firstName', 'lastName')) if user['name']
    id_token
  end

  def claims(token)
    token
  end

  def generate_authorize_url(redirect_uri, state)
    # wtf Apple https://forums.developer.apple.com/thread/122458
    # we _could_ update faraday, which has been fixed to deal with this as well,
    # but that's a long rabbit whole of other gems that would need updating and
    # have very large breaking changes, so far riskier
    super.gsub('+', '%20')
  end

  protected

  def authorize_url
    "https://appleid.apple.com/auth/authorize"
  end

  def authorize_options
    { scope: scope, response_type: 'code id_token', response_mode: 'form_post' }
  end

  def scope
    result = []
    requested_attributes = [login_attribute] + federated_attributes.values.map { |v| v['attribute'] }
    result << 'name' unless (requested_attributes & ['firstName', 'lastName']).empty?
    result << 'email' if requested_attributes.include?('email')
    result.join(' ')
  end

  # fetch from https://appleid.apple.com/auth/keys
  def apple_public_keys
    keys_json = Setting.get('apple_public_key', nil).presence ||
      CanvasHttp.get('https://appleid.apple.com/auth/keys').body
    JSON::JWK::Set.new(JSON.parse(keys_json))
  end
end
