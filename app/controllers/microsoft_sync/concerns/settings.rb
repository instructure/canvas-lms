# frozen_string_literal: true
#
# Copyright (C) 2021 - present Instructure, Inc.
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

module MicrosoftSync::Concerns
  module Settings
    extend ActiveSupport::Concern

    VALID_SYNC_LOGIN_ATTRIBUTES = %w(email preferred_username sis_user_id).freeze

    def set_microsoft_sync_settings(enabled, tenant, login_attribute)
      return if enabled.nil? && tenant.blank? && login_attribute.blank?
      return unless valid_settings?(enabled, tenant, login_attribute)

      @account.settings[:microsoft_sync_enabled] = format_enabled(enabled)
      @account.settings[:microsoft_sync_tenant] = format_tenant(tenant)
      @account.settings[:microsoft_sync_login_attribute] = format_login_attribute(login_attribute)
    end

    def format_enabled(sync_enabled)
      ActiveModel::Type::Boolean.new.cast(sync_enabled)
    end

    # A valid tenant is effectively a domain name (ex: canvastest2.onmicrosoft.com), consisting
    # of alphanumeric characters, with the restriction that each subdomain cannot start or end with
    # a hyphen. Normally we would use something like URI.parse(tenant), but that allows domains
    # that aren't valid, so we had to make a custom regex.
    def format_tenant(tenant)
      return nil if tenant.blank?

      tenant = tenant.strip
      # Uses look ahead and look behind to ensure we don't start/end with hyphens in any subdomains/TLD
      regex = /^((?!-)[A-Za-z0-9-]+(?<!-)\.)+(?!-)[A-Za-z0-9-]+(?<!-)$/
      return tenant if tenant =~ regex

      nil
    end

    def format_login_attribute(login_attr)
      return nil unless VALID_SYNC_LOGIN_ATTRIBUTES.include?(login_attr)

      login_attr
    end

    # Checks if the passed settings are valid, and adds error messages as appropriate
    def valid_settings?(enabled, tenant, attribute)
      unless @account.root_account.feature_enabled?(:microsoft_group_enrollments_syncing)
        @account.errors.add(:bad_request,
                            t("This account doesn't allow for Microsoft Teams sync to be enabled. Please enable the \"Microsoft Group enrollment syncing\" feature flag before editing any settings"))
        return false
      end
      enabled = format_enabled(enabled)
      if enabled.nil?
        @account.errors.add(:bad_request, t("You must specify whether to enable or disable Microsoft Teams sync"))
        false
      elsif enabled && (tenant.blank? || attribute.blank?)
        @account.errors.add(:bad_request, t("You must provide a tenant and login attribute to enabled Microsoft Teams sync"))
        false
      elsif enabled && format_tenant(tenant).blank?
        @account.errors.add(:bad_request, t("Invalid Microsoft Sync tenant given. Please validate your tenant"))
        false
      elsif enabled && format_login_attribute(attribute).blank?
        @account.errors.add(:bad_request,
                            t("Invalid Microsoft Teams Sync login attribute. Valid login attributes: %{valid_attributes}",
                              valid_attributes: VALID_SYNC_LOGIN_ATTRIBUTES.to_sentence(:or)))
        false
      end
      true
    end
  end
end
