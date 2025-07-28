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

class AuthenticationProvider::GitHub < AuthenticationProvider::OAuth2
  include AuthenticationProvider::PluginSettings
  self.plugin = :github
  plugin_settings :domain, :client_id, client_secret: :client_secret_dec

  def self.sti_name
    "github"
  end

  def self.recognized_params
    super + [:login_attribute, :jit_provisioning].freeze
  end

  def self.login_attributes
    %w[id email login].freeze
  end
  validates :login_attribute, inclusion: login_attributes

  def self.recognized_federated_attributes
    %w[
      email
      id
      login
      name
    ].freeze
  end

  def self.supports_autoconfirmed_email?
    false
  end

  # Rename db field
  alias_attribute :domain, :auth_host

  def unique_id(token)
    user(token)[login_attribute].to_s
  end

  def provider_attributes(token)
    user(token)
  end

  def login_attribute
    super || "id"
  end

  protected

  def user(token)
    token.options[:user] ||= begin
      user = token.get("user").parsed
      if !user["email"] && authorize_options[:scope]
        user["email"] = token.get("user/emails").parsed.find { |e| e["primary"] }.try(:[], "email")
      end
      user
    end
  end

  def authorize_options
    res = {}
    res[:scope] = "user:email" if login_attribute == "email" ||
                                  federated_attributes.any? { |(_k, v)| v["attribute"] == "email" }
    res
  end

  def client_options
    {
      site: domain.present? ? "https://#{domain}/api/v3" : "https://api.github.com",
      authorize_url: "https://#{inferred_domain}/login/oauth/authorize",
      token_url: "https://#{inferred_domain}/login/oauth/access_token"
    }
  end

  def inferred_domain
    domain.presence || "github.com"
  end
end
