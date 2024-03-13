# frozen_string_literal: true

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

class AuthenticationProvider::Facebook < AuthenticationProvider::OAuth2
  include AuthenticationProvider::PluginSettings

  self.plugin = :facebook
  plugin_settings :app_id, app_secret: :app_secret_dec

  SENSITIVE_PARAMS = [:app_secret].freeze

  alias_attribute :app_id, :entity_id
  alias_method :app_secret, :client_secret
  alias_method :app_secret=, :client_secret=

  def client_id
    app_id
  end

  # yes this seems duplicative of the alias_method above, but it's necessary.
  # PluginSettings will define a method app_secret in a module prepended to
  # this class; that method will call super, which needs to call the "raw"
  # app_secret method created above. But OAuth2 (the parent to this class)
  # will call client_secret, and we need it to return the app_secret, as
  # defined by PluginSettings. We also can't simply use alias_method, since
  # that will copy app_secret (back!) in this class, instead of calling
  # app_secret as defined in the prepended module
  def client_secret
    app_secret
  end

  def self.recognized_params
    super + [:login_attribute, :jit_provisioning].freeze
  end

  def self.login_attributes
    ["id", "email"].freeze
  end
  validates :login_attribute, inclusion: login_attributes

  def self.recognized_federated_attributes
    %w[
      email
      first_name
      id
      last_name
      locale
      name
    ].freeze
  end

  def login_attribute
    super || "id"
  end

  def unique_id(token)
    me(token)[login_attribute]
  end

  def provider_attributes(token)
    me(token)
  end

  protected

  def me(token)
    # abusing AccessToken#options as a useful place to cache this response
    token.options[:me] ||= begin
      attributes = ([login_attribute] + federated_attributes.values.pluck("attribute")).uniq
      token.get("me?fields=#{attributes.join(",")}").parsed
    end
  end

  def authorize_options
    if login_attribute == "email" || federated_attributes.any? { |(_k, v)| v["attribute"] == "email" }
      { scope: "email" }.freeze
    else
      {}.freeze
    end
  end

  def client_options
    {
      site: "https://graph.facebook.com",
      authorize_url: "https://www.facebook.com/dialog/oauth",
      token_url: "oauth/access_token"
    }
  end
end
