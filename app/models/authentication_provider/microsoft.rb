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
  # Tenant IDs are always GUIDs, but we will translate the GUID for
  # the Microsoft personal account tenant to "microsoft" for ease
  # of identification. "guests" and "common" are special cases that
  # trigger special processing
  MICROSOFT_TENANT = "9188040d-6c67-4c5b-b112-36a304b66dad"
  WELL_KNOWN_TENANTS = %w[microsoft guests common].freeze
  GUID_REGEX = /^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$/

  def self.singleton?
    false
  end

  alias_attribute :application_id, :entity_id
  alias_attribute :tenant, :auth_filter
  alias_method :application_secret, :client_secret
  alias_method :application_secret=, :client_secret=
  alias_method :login_attribute_for_pseudonyms, :login_attribute

  validates :tenants, presence: true
  validate :tenants, :validate_tenants
  validate :login_attribute, :validate_secure_login_attribute

  def client_id
    application_id
  end

  # see {Facebooke#client_secret} for the reasoning here
  def client_secret
    application_secret
  end

  def self.recognized_params
    # need to filter out OpenIDConnect params, but still call super to get mfa_required
    super - open_id_connect_params + %i[tenant login_attribute jit_provisioning tenants].freeze
  end

  def self.login_attributes
    %w[tid+oid sub email oid preferred_username].freeze
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

  def self.supports_autoconfirmed_email?
    false
  end

  def login_attribute
    raw_login_attribute || "tid+oid"
  end

  def unique_id(token)
    id_token = claims(token)
    settings["known_tenants"] ||= []
    (settings["known_tenants"] << id_token["tid"]).uniq!
    allowed_tenants = mapped_allowed_tenants
    if allowed_tenants.empty? || allowed_tenants.include?("common") || settings["skip_tenant_verification"]
      # allow anyone
    elsif allowed_tenants.delete("guests")
      # just check the issuer
      unless allowed_tenants.find { |tenant| id_token["iss"] == "https://login.microsoftonline.com/#{tenant}/v2.0" }
        raise OAuthValidationError, t("User is from unacceptable issuer %{issuer}.", issuer: id_token["iss"].inspect)
      end
    elsif !allowed_tenants.include?(id_token["tid"])
      raise OAuthValidationError, t("User is from unacceptable tenant %{tenant}.", tenant: id_token["tid"].inspect)
    end

    settings["known_idps"] ||= []
    idp = id_token["idp"] || id_token["iss"]
    (settings["known_idps"] << idp).uniq!
    save! if changed?

    ids = id_token.as_json
    ids["tid+oid"] = "#{ids["tid"]}##{ids["oid"]}" if ids["tid"] && ids["oid"]
    ids.slice("tid", *self.class.login_attributes)
  end

  # always process through the multi-valued setter
  def tenant=(value)
    self.tenants = value
  end

  def tenants=(value)
    value = value.split(",") if value.is_a?(String)
    value = value.filter_map(&:strip).uniq
    value << "microsoft" if value.delete(MICROSOFT_TENANT)
    value = ["common"] if value.include?("common")
    self["tenant"] = value.first
    settings["allowed_tenants"] = value[1..]
  end

  def tenants
    [tenant.presence].compact + (settings["allowed_tenants"] || [])
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
    result << "profile" if requested_attributes.intersect?(%w[name oid preferred_username tid+oid])
    result << "email" if requested_attributes.include?("email")
    result.join(" ")
  end

  def mapped_allowed_tenants(tenants = self.tenants)
    tenants.map do |tenant|
      next MICROSOFT_TENANT if tenant == "microsoft"

      tenant
    end
  end

  def tenant_value
    tenants = mapped_allowed_tenants
    tenants.delete("guests")
    return "common" if tenants.length != 1 || tenants == ["common"]

    tenants.first
  end

  def validate_tenants
    tenants.each do |tenant|
      next if WELL_KNOWN_TENANTS.include?(tenant)
      next if GUID_REGEX.match?(tenant)

      errors.add(:base, t("Invalid tenant %{tenant}", tenant: tenant.inspect))
    end

    if tenants == ["guests"]
      errors.add(:base, t('"guests" cannot be the only allowed tenant'))
    end

    if mapped_allowed_tenants - [MICROSOFT_TENANT] == ["guests"]
      errors.add(:base, t('"guests" cannot be used with the "microsoft" tenant'))
    end
  end

  def validate_secure_login_attribute
    # don't error out on this if we already errored on empty tenants
    return if tenants.empty?

    tenants = mapped_allowed_tenants
    tenants.delete("guests")

    if tenants.include?("common")
      unless login_attribute == "tid+oid"
        errors.add(:base, t('Only "tid+oid" is supported with the "common" tenant'))
      end
      return
    end

    if tenants.length > 1 && login_attribute == "oid"
      errors.add(:base, t('"oid" cannot be used with multiple tenants'))
    end

    return unless jit_provisioning?

    if tenants.include?(MICROSOFT_TENANT)
      if tenants == [MICROSOFT_TENANT]
        unless ["sub", "tid+oid", "oid"].include?(login_attribute)
          errors.add(:base, t('Only "tid+oid", "sub", or "oid" are supported with the "microsoft" tenant'))
        end
      elsif !["sub", "tid+oid"].include?(login_attribute)
        errors.add(:base, t('Only "tid+oid" or "sub" are supported with the "microsoft" tenant'))
      end
    end
  end
end
