# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module NewLoginHelper
  # returns a hash of login-related data attributes for the new login UI
  # keys with nil values are omitted via `.compact`, and booleans are
  # coerced to strings only when true (to match expected DOM attributes)
  # some values are JSON-encoded for use as typed objects on the frontend
  def new_login_data_attributes
    {
      enable_course_catalog:,
      auth_providers:,
      login_handle_name:,
      login_logo_url:,
      login_logo_text:,
      body_bg_color:,
      body_bg_image:,
      is_preview_mode: preview_mode,
      self_registration_type:,
      recaptcha_key:,
      terms_required:,
      terms_of_use_url: tou_url,
      privacy_policy_url: pp_url,
      require_email:,
      password_policy:,
      forgot_password_url:,
      invalid_login_faq_url:,
      help_link: help_link_info,
      require_aup:,
    }.compact
  end

  private

  # course catalog link for display in the top navigation bar
  def enable_course_catalog
    @domain_root_account&.enable_course_catalog? && "true"
  end

  # returns a simplified version of authentication providers
  def auth_providers
    data = auth_providers_with_buttons.map do |provider|
      {
        id: provider.id,
        auth_type: provider.auth_type,
        display_name: provider.class.display_name
      }
    end
    data.presence && data.to_json
  end

  # “Authentication Settings” customizable “Login Label”
  def login_handle_name
    @domain_root_account&.login_handle_name_with_inference.presence
  end

  # “Themes” custom organization logo as defined in the “Current theme”
  def login_logo_url
    logo = brand_variable("ic-brand-Login-logo").presence
    default = BrandableCSS.brand_variable_value("ic-brand-Login-logo")
    (logo && logo != default) ? logo : nil
  end

  # short_name for use as alt text only if a custom logo is present
  def login_logo_text
    login_logo_url.present? ? @domain_root_account.short_name.presence : nil
  end

  # background color for the login page from brand variables
  def body_bg_color
    brand_variable("ic-brand-Login-body-bgd-color").presence
  end

  # background image URL for the login page from brand variables
  def body_bg_image
    brand_variable("ic-brand-Login-body-bgd-image").presence
  end

  # theme editor preview mode boolean
  def preview_mode
    "true" if params[:previewing_from_themeeditor].to_s.downcase == "true"
  end

  # “Authentication Settings” Canvas provider self-registration (none, all, observer)
  def self_registration_type
    return nil unless @domain_root_account&.self_registration?

    value = @domain_root_account.self_registration_type
    %w[all observer].include?(value) ? value : nil
  end

  # reCAPTCHA site key for the current domain, if configured
  def recaptcha_key
    @domain_root_account&.recaptcha_key.presence
  end

  # whether the current domain requires users to accept terms on login
  def terms_required
    @domain_root_account&.terms_required? && "true"
  end

  # URL for the terms of use, if configured for the current domain
  def tou_url
    terms_of_use_url.presence
  end

  # URL for the privacy policy, if configured for the current domain
  def pp_url
    privacy_policy_url.presence
  end

  # whether email is required for self-registration on the current domain
  def require_email
    @domain_root_account&.require_email_for_registration? && "true"
  end

  # password policy rules as a hash, or nil if none are configured
  def password_policy
    data = @domain_root_account&.password_policy&.slice(
      :minimum_character_length,
      :require_number_characters,
      :require_symbol_characters
    )&.compact

    data.presence && data.to_json
  end

  # custom forgot password URL (can be overridden using the query string ?canvas_login=1)
  def forgot_password_url
    return nil if params[:canvas_login] == "1"

    @domain_root_account&.forgot_password_external_url.presence
  end

  # invalid login FAQ URL as configured in the account settings
  def invalid_login_faq_url
    Setting.get("invalid_login_faq_url", nil).presence
  end

  # help link attributes as a hash, or nil if no name is present
  def help_link_info
    return nil unless help_link_name.present?

    {
      text: help_link_name,
      trackCategory: help_link_data[:"track-category"],
      trackLabel: help_link_data[:"track-label"]
    }.to_json
  end

  def auth_providers_with_buttons
    @domain_root_account.authentication_providers.active.select do |aac|
      aac.class.login_button?
    end
  end

  def require_aup
    (TermsOfService.ensure_terms_for_account(@domain_root_account)&.terms_type == "no_terms") ? nil : "true"
  end
end
