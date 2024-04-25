# frozen_string_literal: true

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

  SENSITIVE_PARAMS = [:application_secret].freeze

  def self.singleton?
    false
  end

  alias_attribute :application_id, :entity_id
  alias_attribute :tenant, :auth_filter
  alias_method :application_secret, :client_secret
  alias_method :application_secret=, :client_secret=

  def client_id
    application_id
  end

  # see {Facebooke#client_secret} for the reasoning here
  def client_secret
    application_secret
  end

  def self.recognized_params
    # need to filter out OpenIDConnect params, but still call super to get mfa_required
    super - open_id_connect_params + %i[tenant login_attribute jit_provisioning].freeze
  end

  def self.login_attributes
    %w[sub email oid preferred_username].freeze
  end
  validates :login_attribute, inclusion: login_attributes

  def self.recognized_federated_attributes
    %w[
      email
      name
      preferred_username
      oid
      sub
    ].freeze
  end

  def login_attribute
    super || "id"
  end

  def unique_id(token)
    id_token = claims(token)
    settings["known_tenants"] ||= []
    (settings["known_tenants"] << id_token["tid"]).uniq!
    settings["known_idps"] ||= []
    idp = id_token["idp"] || id_token["iss"]
    (settings["known_idps"] << idp).uniq!
    save! if changed?
    id_token[login_attribute]
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
    requested_attributes = [login_attribute] + federated_attributes.values.pluck("attribute")
    result << "profile" if requested_attributes.intersect?(%w[name oid preferred_username])
    result << "email" if requested_attributes.include?("email")
    result.join(" ")
  end

  def tenant_value
    tenant.presence || "common"
  end
end
