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

  class << self
    def login_message
      display_name
    end

    def sti_name
      "apple"
    end

    def singleton?
      true
    end

    def login_attributes
      ["sub", "email"].freeze
    end

    def recognized_params
      [*(super - open_id_connect_params), :login_attribute, :jit_provisioning].freeze
    end

    def sensitive_params
      [*super, :client_secret].freeze
    end

    def recognized_federated_attributes
      %w[
        email
        firstName
        lastName
        sub
      ].freeze
    end

    def supports_autoconfirmed_email?
      false
    end

    # few enough schools use Apple auth, that we can just use the regular cache
    def jwks_cache
      Rails.cache
    end
  end
  validates :login_attribute, inclusion: login_attributes

  def issuer
    "https://appleid.apple.com"
  end

  Token = Struct.new(:params, :options)
  private_constant :Token

  def get_token(_code, _redirect_uri, params)
    # all we need is given as a parameter in the callback; don't
    # attempt to actually fetch a token
    Token.new(params, {})
  end

  def claims(token)
    id_token = super
    user = JSON.parse(token.params[:user]) if token.params[:user]
    id_token.merge!(user["name"].slice("firstName", "lastName")) if user && user["name"]
    id_token
  end

  def jwks_uri
    "https://appleid.apple.com/auth/keys"
  end

  def persist_to_session(_request, _session, _pseudonym, _domain_root_account, _token)
    # Apple doesn't support single log out of any kind;
    # don't waste space in the session supporting it
  end

  private

  def authorize_url
    "https://appleid.apple.com/auth/authorize"
  end

  def authorize_options
    { scope:, response_type: "code id_token", response_mode: "form_post" }
  end

  def scope
    result = []
    requested_attributes = [login_attribute] + federated_attributes.values.pluck("attribute")
    result << "name" if requested_attributes.intersect?(["firstName", "lastName"])
    result << "email" if requested_attributes.include?("email")
    result.join(" ")
  end

  def download_jwks(...)
    # cache against the default shard
    Shard.default.activate do
      super
    end
  end
end
