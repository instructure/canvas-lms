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

describe NewLoginHelper do
  include ApplicationHelper
  include NewLoginHelper

  before do
    @domain_root_account = account_model(
      name: "My School",
      settings: {
        enable_course_catalog: true,
        help_link_icon: "icon-help",
        help_link_name: "Get Help",
        password_policy: {
          "minimum_character_length" => "10",
          "require_number_characters" => "true",
          "require_symbol_characters" => "false"
        },
        require_email_for_registration: true
      }
    )
    AuthenticationProvider::Canvas.create!(
      account: @domain_root_account,
      auth_type: "canvas",
      self_registration: "all"
    )
    AuthenticationProvider::Google.create!(account: @domain_root_account, auth_type: "google")
    AuthenticationProvider::Facebook.create!(account: @domain_root_account, auth_type: "facebook")
    allow(BrandableCSS).to receive(:brand_variable_value).and_return("default-color")
    allow(self).to receive_messages(
      params: { previewing_from_themeeditor: "true" },
      brand_variable: "custom-color",
      terms_of_use_url: "https://school.canvas.com/terms",
      privacy_policy_url: "https://school.canvas.com/privacy",
      help_link_data: { "track-category": "Login", "track-label": "Help Link" }
    )
    allow(Setting).to receive(:get).with("invalid_login_faq_url", nil).and_return("https://school.canvas.com/faq")
    allow(Setting).to receive(:get).with("terms_required", "true").and_return("true")
    allow(@domain_root_account).to receive_messages(
      self_registration_type: "all",
      self_registration?: true,
      require_email_for_registration?: true,
      forgot_password_external_url: "https://forgot.com",
      recaptcha_key: "xyz123",
      account_terms_required?: true
    )
  end

  it "returns correct data attributes" do
    data = new_login_data_attributes
    expect(data[:enable_course_catalog]).to eq("true")
    expect(data[:auth_providers]).not_to include("canvas")
    expect(data[:auth_providers]).to include("google")
    expect(data[:auth_providers]).to include("facebook")
    expect(data[:login_handle_name]).to eq("Email")
    expect(data[:login_logo_url]).to eq("custom-color")
    expect(data[:login_logo_text]).to eq("My School")
    expect(data[:body_bg_color]).to eq("custom-color")
    expect(data[:body_bg_image]).to eq("custom-color")
    expect(data[:is_preview_mode]).to eq("true")
    expect(data[:self_registration_type]).to eq("all")
    expect(data[:recaptcha_key]).to eq("xyz123")
    expect(data[:terms_required]).to eq("true")
    expect(data[:terms_of_use_url]).to eq("https://school.canvas.com/terms")
    expect(data[:privacy_policy_url]).to eq("https://school.canvas.com/privacy")
    expect(data[:require_email]).to eq("true")
    expect(data[:forgot_password_url]).to eq("https://forgot.com")
    expect(data[:invalid_login_faq_url]).to eq("https://school.canvas.com/faq")
    expect(data[:password_policy]).to be_a(String)
    expect(JSON.parse(data[:password_policy])).to include(
      "minimum_character_length" => "10",
      "require_number_characters" => "true",
      "require_symbol_characters" => "false"
    )
    expect(data[:help_link]).to include("Get Help")
    expect(data[:require_aup]).to eq("true")
    terms = TermsOfService.ensure_terms_for_account(@domain_root_account)
    expect(terms.passive).to be(false)
    expect(terms.terms_type).to eq("default")
    expect(data).to be_a(Hash)
  end
end
