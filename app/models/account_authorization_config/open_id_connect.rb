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

class AccountAuthorizationConfig::OpenIDConnect < AccountAuthorizationConfig::Oauth2
  def self.sti_name
    self == OpenIDConnect ? 'openid_connect'.freeze : super
  end

  def self.display_name
    self == OpenIDConnect ? 'OpenID Connect'.freeze : super
  end

  def self.recognized_params
    [ :client_id,
      :client_secret,
      :authorize_url,
      :token_url,
      :scope,
      :login_attribute,
      :end_session_endpoint,
      :jit_provisioning ].freeze
  end

  def end_session_endpoint=(value)
    self.log_out_url = value
  end

  def end_session_endpoint
    log_out_url
  end

  def login_attribute
    super || 'sub'.freeze
  end

  def unique_id(token)
    jwt_string = token.params['id_token'.freeze]
    jwt = ::Canvas::Security.decode_jwt(jwt_string, [:skip_verification])
    jwt[login_attribute]
  end

  def user_logout_redirect(_controller, _current_user)
    end_session_endpoint.presence
  end

  protected

  def authorize_options
    { scope: scope_for_options }
  end

  private

  def scope_for_options
    result = (scope || ''.freeze).split(' '.freeze)
    result.unshift('openid'.freeze) unless result.include?('openid'.freeze)
    result.join(' '.freeze)
  end
end
