# frozen_string_literal: true

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

class AuthenticationProvider::OpenIDConnect < AuthenticationProvider::OAuth2
  attr_accessor :instance_debugging

  def self.sti_name
    (self == OpenIDConnect) ? "openid_connect" : super
  end

  def self.display_name
    (self == OpenIDConnect) ? "OpenID Connect" : super
  end

  def self.open_id_connect_params
    %i[client_id
       client_secret
       authorize_url
       token_url
       scope
       login_attribute
       end_session_endpoint
       userinfo_endpoint
       jit_provisioning].freeze
  end

  def self.recognized_params
    super + open_id_connect_params
  end

  def self.recognized_federated_attributes
    return super unless self == OpenIDConnect

    # we allow any attribute
    nil
  end

  def self.supports_debugging?
    debugging_enabled?
  end

  def self.debugging_sections
    [nil]
  end

  def self.debugging_keys
    [{
      debugging: -> { t("Testing state") },
      nonce: -> { t("Nonce") },
      authorize_url: -> { t("Authorize URL") },
      get_token_response: -> { t("Error fetching access token") },
      claims_response: -> { t("Error fetching user details") },
      id_token: -> { t("ID Token") },
      userinfo: -> { t("Userinfo") },
    }]
  end

  alias_attribute :end_session_endpoint, :log_out_url

  def raw_login_attribute
    read_attribute(:login_attribute).presence
  end

  def login_attribute
    super.presence || "sub"
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
    settings["userinfo_endpoint"]
  end

  def userinfo_endpoint=(value)
    value = value.presence
    unless userinfo_endpoint == value
      settings_will_change!
      settings["userinfo_endpoint"] = value
    end
  end

  protected

  def authorize_options
    { scope: scope_for_options }
  end

  def client_options
    super.merge(auth_scheme: :request_body)
  end

  private

  def claims(token)
    token.options[:claims] ||= begin
      jwt_string = token.params["id_token"] || token.token
      debug_set(:id_token, jwt_string) if instance_debugging
      id_token = {} if jwt_string.blank?

      id_token ||= begin
        ::Canvas::Security.decode_jwt(jwt_string, [:skip_verification])
      rescue ::Canvas::Security::InvalidToken
        Rails.logger.warn("Failed to decode OpenID Connect id_token: #{jwt_string.inspect}")
        raise
      end
      # we have a userinfo endpoint, and we don't have everything we want,
      # then request more
      if userinfo_endpoint.present? && !(id_token.keys - requested_claims).empty?
        userinfo = token.get(userinfo_endpoint).parsed
        debug_set(:userinfo, userinfo.to_json) if instance_debugging
        # but only use it if it's for the user we logged in as
        # see http://openid.net/specs/openid-connect-core-1_0.html#UserInfoResponse
        if userinfo["sub"] == id_token["sub"]
          id_token.merge!(userinfo)
        end
      end
      id_token
    end
  end

  def requested_claims
    ([login_attribute] + federated_attributes.map { |_canvas_attribute, details| details["attribute"] }).uniq
  end

  PROFILE_CLAIMS = %w[name
                      family_name
                      given_name
                      middle_name
                      nickname
                      preferred_username
                      profile
                      picture
                      website
                      gender
                      birthdate
                      zoneinfo
                      locale
                      updated_at].freeze
  def scope_for_options
    result = (scope || "").split

    result.unshift("openid")
    claims = requested_claims
    # see http://openid.net/specs/openid-connect-core-1_0.html#ScopeClaims
    result << "profile" if claims.intersect?(PROFILE_CLAIMS)
    result << "email" if claims.include?("email") || claims.include?("email_verified")
    result << "address" if claims.include?("address")
    result << "phone" if claims.include?("phone_number") || claims.include?("phone_number_verified")

    result.uniq!
    result.join(" ")
  end
end
