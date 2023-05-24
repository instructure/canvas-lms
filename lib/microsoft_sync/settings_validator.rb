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
#

module MicrosoftSync
  # SettingsHelper is a helper class for validating and saving Microsoft Teams Sync settings. It's
  # primary use is in the Accounts controller.
  class SettingsValidator
    # A list of all sync settings, as a final source of truth.
    SYNC_SETTINGS = %i[microsoft_sync_enabled
                       microsoft_sync_tenant
                       microsoft_sync_login_attribute
                       microsoft_sync_login_attribute_suffix
                       microsoft_sync_remote_attribute].freeze
    VALID_SYNC_LOGIN_ATTRIBUTES = %w[email preferred_username sis_user_id integration_id].freeze
    VALID_SYNC_REMOTE_ATTRIBUTES = %w[userPrincipalName mail mailNickname].freeze

    attr_reader :settings, :account

    def initialize(new_settings, account)
      # We only store symbols for keys on the account settings hash. We use strings for all our
      # values except the one that's obviously a boolean.
      @settings = new_settings.to_h.slice(*SYNC_SETTINGS).symbolize_keys.transform_values(&:to_s)
      unless @settings[:microsoft_sync_enabled].nil?
        @settings[:microsoft_sync_enabled] = ActiveModel::Type::Boolean.new.cast(@settings[:microsoft_sync_enabled])
      end
      @account = account
    end

    def validate_and_save
      return if settings.empty?
      return unless valid_settings?

      if settings_changed?
        MicrosoftSync::UserMapping.delete_old_user_mappings_later(@account)
      end

      account.settings.merge!(@settings)
    end

    private

    def settings_changed?
      old_validated_settings = MicrosoftSync::SettingsValidator.new(account.settings, account).settings
      old_validated_settings != settings
    end

    def enabled
      settings[:microsoft_sync_enabled]
    end

    def tenant
      settings[:microsoft_sync_tenant]
    end

    def login_attribute
      settings[:microsoft_sync_login_attribute]
    end

    def suffix
      settings[:microsoft_sync_login_attribute_suffix]
    end

    def remote_attribute
      settings[:microsoft_sync_remote_attribute]
    end

    # A valid tenant is effectively a domain name (ex: canvastest2.onmicrosoft.com), consisting
    # of alphanumeric characters, with the restriction that each subdomain cannot start or end with
    # a hyphen. Normally we would use something like URI.parse(tenant), but that allows domains
    # that aren't valid, so we had to make a custom regex.
    def tenant_valid?
      # Uses look ahead and look behind to ensure we don't start/end with hyphens in any subdomains/TLD
      regex = /^((?!-)[A-Za-z0-9-]+(?<!-)\.)+(?!-)[A-Za-z0-9-]+(?<!-)$/
      regex.match?(tenant)
    end

    def login_attribute_valid?
      VALID_SYNC_LOGIN_ATTRIBUTES.include?(login_attribute)
    end

    def login_attribute_suffix_valid?
      # API requests are allowed to NOT specify a suffix.
      return true if suffix.nil?

      suffix.length < 255 && !/\s/.match?(suffix)
    end

    def remote_attribute_valid?
      VALID_SYNC_REMOTE_ATTRIBUTES.include?(remote_attribute)
    end

    # Checks if the passed settings are valid, and adds error messages as appropriate
    def valid_settings?
      unless @account.root_account.feature_enabled?(:microsoft_group_enrollments_syncing)
        account.errors.add(:bad_request,
                           I18n.t("This account does not allow for Microsoft Teams sync to be enabled. Please enable the \"Microsoft Group enrollment syncing\" feature flag before editing any settings."))
        return false
      end

      # This is very long, but we want to be specific about what's wrong with their request.
      if enabled.nil?
        account.errors.add(:bad_request, I18n.t("Please specify whether to enable or disable Microsoft Teams sync."))
      elsif enabled && settings.length == 1
        account.errors.add(:bad_request, I18n.t("To enable Microsoft Teams Sync, please provide a tenant, login attribute, and remote attribute."))
      elsif enabled && !tenant_valid?
        account.errors.add(:bad_request, I18n.t("Invalid Microsoft Sync tenant given. Please validate your tenant."))
      elsif enabled && !login_attribute_valid?
        account.errors.add(:bad_request,
                           I18n.t("Invalid Microsoft Teams Sync login attribute. Valid login attributes: %{valid_attributes}",
                                  valid_attributes: VALID_SYNC_LOGIN_ATTRIBUTES.to_sentence(:or)))
      elsif enabled && !login_attribute_suffix_valid?
        account.errors.add(:bad_request,
                           I18n.t("Invalid Microsoft Teams Sync login attribute suffix. A suffix must be less than 255 characters and cannot have any whitespace."))
      elsif enabled && !remote_attribute_valid?
        account.errors.add(:bad_request,
                           I18n.t("Invalid Microsoft Team Sync remote attribute. Valid remote attributes: %{VALID_SYNC_REMOTE_ATTRIBUTES}",
                                  VALID_SYNC_REMOTE_ATTRIBUTES: VALID_SYNC_REMOTE_ATTRIBUTES.to_sentence(:or)))
      end

      account.errors.empty?
    end
  end
end
