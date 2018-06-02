#
# Copyright (C) 2011 - present Instructure, Inc.
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

class AuthenticationProvider::OpenIDConnect < AuthenticationProvider::Oauth2
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
      :userinfo_endpoint,
      :jit_provisioning ].freeze
  end

  def self.recognized_federated_attributes
    return super unless self == OpenIDConnect
    # we allow any attribute
    nil
  end

  alias_attribute :end_session_endpoint, :log_out_url

  def raw_login_attribute
    read_attribute(:login_attribute).presence
  end

  def login_attribute
    super.presence || 'sub'.freeze
  end

  def unique_id(token)
    claims(token)[login_attribute]
  end

  def user_logout_redirect(_controller, _current_user)
    end_session_endpoint.presence || super
  end

  def provider_attributes(token)
    claims(token)
  end

  def userinfo_endpoint
    settings['userinfo_endpoint']
  end

  def userinfo_endpoint=(value)
    value = value.presence
    unless userinfo_endpoint == value
      settings_will_change!
      settings['userinfo_endpoint'] = value
    end
    value
  end

  protected

  def authorize_options
    { scope: scope_for_options }
  end

  private

  def claims(token)
    token.options[:claims] ||= begin
      jwt_string = token.params['id_token']
      id_token = ::Canvas::Security.decode_jwt(jwt_string, [:skip_verification])
      # we have a userinfo endpoint, and we don't have everything we want,
      # then request more
      if userinfo_endpoint.present? && !(id_token.keys - requested_claims).empty?
        userinfo = token.get(userinfo_endpoint).parsed
        # but only use it if it's for the user we logged in as
        # see http://openid.net/specs/openid-connect-core-1_0.html#UserInfoResponse
        if userinfo['sub'] == id_token['sub']
          id_token.merge!(userinfo)
        end
      end
      id_token
    end
  end

  def requested_claims
    ([login_attribute] + federated_attributes.map { |_canvas_attribute, details| details['attribute'] }).uniq
  end

  PROFILE_CLAIMS = ['name', 'family_name', 'given_name', 'middle_name', 'nickname', 'preferred_username',
                    'profile', 'picture', 'website', 'gender', 'birthdate', 'zoneinfo', 'locale', 'updated_at'].freeze
  def scope_for_options
    result = (scope || ''.freeze).split(' '.freeze)

    result.unshift('openid'.freeze)
    claims = requested_claims
    # see http://openid.net/specs/openid-connect-core-1_0.html#ScopeClaims
    result << 'profile' unless (claims & PROFILE_CLAIMS).empty?
    result << 'email' if claims.include?('email') || claims.include?('email_verified')
    result << 'address' if claims.include?('address')
    result << 'phone' if claims.include?('phone_number') || claims.include?('phone_number_verified')

    result.uniq!
    result.join(' '.freeze)
  end
end
