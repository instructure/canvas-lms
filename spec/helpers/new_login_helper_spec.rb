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

  let(:brand_config) { instance_double(BrandConfig, get_value: nil) }

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
      active_brand_config: brand_config,
      params: { previewing_from_themeeditor: "true" },
      brand_variable: "custom-color",
      terms_of_use_url: "https://school.canvas.com/terms",
      privacy_policy_url: "https://school.canvas.com/privacy",
      help_link_data: { "track-category": "Login", "track-label": "Help Link" }
    )
    allow(Setting).to receive(:get).and_call_original
    allow(Setting).to receive(:get).with("terms_required", "true").and_return("true")
    @domain_root_account.login_help_url = "https://school.canvas.com/faq"
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

  describe "invalid_login_faq_url" do
    it "prefers the account setting over the global setting" do
      @domain_root_account.login_help_url = "https://account-level.com/faq"
      allow(Setting).to receive(:get).with("invalid_login_faq_url", nil).and_return("https://global.com/faq")
      expect(new_login_data_attributes[:invalid_login_faq_url]).to eq("https://account-level.com/faq")
    end

    it "falls back to the global setting when the account setting is blank" do
      @domain_root_account.login_help_url = nil
      allow(Setting).to receive(:get).with("invalid_login_faq_url", nil).and_return("https://global.com/faq")
      expect(new_login_data_attributes[:invalid_login_faq_url]).to eq("https://global.com/faq")
    end

    it "returns nil when both the account and global settings are blank" do
      @domain_root_account.login_help_url = nil
      allow(Setting).to receive(:get).with("invalid_login_faq_url", nil).and_return(nil)
      expect(new_login_data_attributes[:invalid_login_faq_url]).to be_nil
    end
  end

  describe "custom message methods" do
    before do
      Account.site_admin.enable_feature!(:new_login_ui_custom_labels)
    end

    describe "#custom_message_for" do
      it "returns the brand config value when present" do
        allow(brand_config).to receive(:get_value).with("ic-brand-Login-custom-message").and_return("Welcome to login!")
        expect(custom_message_for("ic-brand-Login-custom-message")).to eq("Welcome to login!")
      end

      it "strips leading and trailing whitespace" do
        allow(brand_config).to receive(:get_value).with("ic-brand-Login-custom-message").and_return("  Welcome!  ")
        expect(custom_message_for("ic-brand-Login-custom-message")).to eq("Welcome!")
      end

      it "replaces newlines with spaces" do
        allow(brand_config).to receive(:get_value).with("ic-brand-Login-custom-message").and_return("Welcome\nto\r\nlogin!")
        expect(custom_message_for("ic-brand-Login-custom-message")).to eq("Welcome to login!")
      end

      it "replaces multiple consecutive newlines with a single space" do
        allow(brand_config).to receive(:get_value).with("ic-brand-Login-custom-message").and_return("Welcome\n\n\nto login!")
        expect(custom_message_for("ic-brand-Login-custom-message")).to eq("Welcome to login!")
      end

      it "returns nil when value is nil" do
        allow(brand_config).to receive(:get_value).with("ic-brand-Login-custom-message").and_return(nil)
        expect(custom_message_for("ic-brand-Login-custom-message")).to be_nil
      end

      it "returns nil when value is empty string" do
        allow(brand_config).to receive(:get_value).with("ic-brand-Login-custom-message").and_return("")
        expect(custom_message_for("ic-brand-Login-custom-message")).to be_nil
      end

      it "returns nil when value is only whitespace" do
        allow(brand_config).to receive(:get_value).with("ic-brand-Login-custom-message").and_return("   \n  ")
        expect(custom_message_for("ic-brand-Login-custom-message")).to be_nil
      end
    end

    describe "#custom_message_login" do
      it "returns the login custom message" do
        allow(brand_config).to receive(:get_value).with("ic-brand-Login-custom-message").and_return("Login message")
        expect(custom_message_login).to eq("Login message")
      end

      it "returns nil when no login message is set" do
        allow(brand_config).to receive(:get_value).with("ic-brand-Login-custom-message").and_return(nil)
        expect(custom_message_login).to be_nil
      end
    end

    describe "#custom_message_registration" do
      it "returns the registration custom message" do
        allow(brand_config).to receive(:get_value).with("ic-brand-Registration-custom-message").and_return("Registration message")
        expect(custom_message_registration).to eq("Registration message")
      end

      it "returns nil when no registration message is set" do
        allow(brand_config).to receive(:get_value).with("ic-brand-Registration-custom-message").and_return(nil)
        expect(custom_message_registration).to be_nil
      end
    end

    describe "#custom_message_registration_parent" do
      it "returns the parent registration custom message" do
        allow(brand_config).to receive(:get_value).with("ic-brand-Registration-parent-custom-message").and_return("Parent registration message")
        expect(custom_message_registration_parent).to eq("Parent registration message")
      end

      it "returns nil when no parent registration message is set" do
        allow(brand_config).to receive(:get_value).with("ic-brand-Registration-parent-custom-message").and_return(nil)
        expect(custom_message_registration_parent).to be_nil
      end
    end

    describe "integration with new_login_data_attributes" do
      it "includes custom messages in data attributes when present" do
        allow(brand_config).to receive(:get_value).with("ic-brand-Login-custom-message").and_return("Login msg")
        allow(brand_config).to receive(:get_value).with("ic-brand-Registration-custom-message").and_return("Registration msg")
        allow(brand_config).to receive(:get_value).with("ic-brand-Registration-parent-custom-message").and_return("Parent msg")
        data = new_login_data_attributes
        expect(data[:custom_message_login]).to eq("Login msg")
        expect(data[:custom_message_registration]).to eq("Registration msg")
        expect(data[:custom_message_registration_parent]).to eq("Parent msg")
      end

      it "omits custom messages from data attributes when nil (via compact)" do
        allow(brand_config).to receive(:get_value).with("ic-brand-Login-custom-message").and_return(nil)
        allow(brand_config).to receive(:get_value).with("ic-brand-Registration-custom-message").and_return(nil)
        allow(brand_config).to receive(:get_value).with("ic-brand-Registration-parent-custom-message").and_return(nil)
        data = new_login_data_attributes
        expect(data).not_to have_key(:custom_message_login)
        expect(data).not_to have_key(:custom_message_registration)
        expect(data).not_to have_key(:custom_message_registration_parent)
      end
    end

    context "when new_login_ui_custom_labels feature flag is disabled" do
      before do
        Account.site_admin.disable_feature!(:new_login_ui_custom_labels)
      end

      it "returns nil from custom_message_for even when brand config has a value" do
        allow(brand_config).to receive(:get_value).with("ic-brand-Login-custom-message").and_return("Login message")
        expect(custom_message_for("ic-brand-Login-custom-message")).to be_nil
      end

      it "omits all custom messages from data attributes" do
        allow(brand_config).to receive(:get_value).with("ic-brand-Login-custom-message").and_return("Login msg")
        allow(brand_config).to receive(:get_value).with("ic-brand-Registration-custom-message").and_return("Registration msg")
        allow(brand_config).to receive(:get_value).with("ic-brand-Registration-parent-custom-message").and_return("Parent msg")
        data = new_login_data_attributes
        expect(data).not_to have_key(:custom_message_login)
        expect(data).not_to have_key(:custom_message_registration)
        expect(data).not_to have_key(:custom_message_registration_parent)
      end
    end

    it "does not raise when there is no explicit custom message value" do
      expect { new_login_data_attributes }.not_to raise_error
    end

    it "does not raise when there is no active brand config" do
      allow(self).to receive(:active_brand_config).and_return(nil)
      expect { new_login_data_attributes }.not_to raise_error
    end
  end
end
