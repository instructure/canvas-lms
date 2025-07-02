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

describe "login/canvas/new_login" do
  subject(:rendered_page) do
    render
    Nokogiri::HTML5(rendered)
  end

  let(:account) { Account.default }

  let!(:apple_provider) do
    account.authentication_providers.create!(auth_type: "apple")
  end

  let!(:google_provider) do
    account.authentication_providers.create!(auth_type: "google")
  end

  let(:attributes) do
    {
      "data-auth-providers" => [
        {
          id: apple_provider.id,
          auth_type: apple_provider.auth_type,
          display_name: apple_provider.class.display_name
        },
        {
          id: google_provider.id,
          auth_type: google_provider.auth_type,
          display_name: google_provider.class.display_name
        }
      ].to_json,
      "data-body-bg-color" => "#ffffff",
      "data-body-bg-image" => "bg.png",
      "data-enable-course-catalog" => "true",
      "data-forgot-password-url" => "http://example.com/forgot",
      "data-help-link" => {
        text: "Help",
        trackCategory: "help system",
        trackLabel: "help button"
      }.to_json,
      "data-invalid-login-faq-url" => "http://example.com/faq",
      "data-is-preview-mode" => "true",
      "data-login-handle-name" => "Username",
      "data-login-logo-text" => "Default Account",
      "data-login-logo-url" => "https://cdn.canvas.com/accounts/1/files/1/download?verifier=abc123",
      "data-password-policy" => {
        minimum_character_length: 8,
        require_number_characters: true,
        require_symbol_characters: true
      }.to_json,
      "data-privacy-policy-url" => "http://example.com/privacy",
      "data-recaptcha-key" => "test-recaptcha-key",
      "data-require-email" => "true",
      "data-self-registration-type" => "all",
      "data-terms-of-use-url" => "http://example.com/terms",
      "data-terms-required" => "true",
      "data-require-aup" => "true",
    }
  end

  let(:login_data) { rendered_page.at_css("#new_login_data") }

  before do
    # assign view variables
    assign(:domain_root_account, account)
    # stub provider class display names
    allow(apple_provider.class).to receive(:display_name).and_return("Apple")
    allow(google_provider.class).to receive(:display_name).and_return("Google")
    # stub account feature flags and settings
    allow(account).to receive_messages(
      enable_course_catalog?: true,
      forgot_password_external_url: "http://example.com/forgot",
      login_handle_name_with_inference: "Username",
      password_policy: {
        minimum_character_length: 8,
        require_number_characters: true,
        require_symbol_characters: true
      },
      recaptcha_key: "test-recaptcha-key",
      require_email_for_registration?: true,
      self_registration?: true,
      self_registration_type: "all",
      account_terms_required?: true
    )
    # stub settings
    allow(Setting).to receive(:get).with("invalid_login_faq_url", nil).and_return("http://example.com/faq")
    allow(Setting).to receive(:get).with("terms_of_use_url", anything).and_return("http://example.com/terms")
    allow(Setting).to receive(:get).with("privacy_policy_url", anything).and_return("http://example.com/privacy")
    allow(Setting).to receive(:get).with("terms_of_use_fft", anything).and_return("http://example.com/terms")
    allow(Setting).to receive(:get).with("privacy_policy_fft", anything).and_return("http://example.com/privacy")
    allow(Setting).to receive(:get).with("terms_required", "true").and_return("true")
    # stub branding variables
    allow(view).to receive(:brand_variable).with("ic-brand-Login-logo").and_return("https://cdn.canvas.com/accounts/1/files/1/download?verifier=abc123")
    allow(view).to receive(:brand_variable).with("ic-brand-Login-body-bgd-color").and_return("#ffffff")
    allow(view).to receive(:brand_variable).with("ic-brand-Login-body-bgd-image").and_return("bg.png")
    # stub view parameters
    allow(view).to receive_messages(
      params: { previewing_from_themeeditor: "true" }
    )
  end

  it "renders the login data div" do
    expect(login_data).not_to be_nil
  end

  it "renders the correct number of data attributes" do
    data_attributes = login_data.attributes.keys.grep(/^data-/)
    # puts "\nrendered data-* keys (#{data_attributes.count}):"
    # data_attributes.each { |attr| puts "  - #{attr}" }
    expect(data_attributes.size).to eq attributes.size
  end

  it "renders the login data div with all expected data-* attributes" do
    aggregate_failures "checking data-* attributes" do
      attributes.each do |attr, expected_value|
        expect(login_data[attr]).to eq(expected_value)
      end
    end
  end

  describe "password policy" do
    context "when set" do
      let(:policy_json) { JSON.parse(login_data["data-password-policy"]) }

      it "renders only the allowed attributes" do
        expected_policy = {
          "minimum_character_length" => 8,
          "require_number_characters" => true,
          "require_symbol_characters" => true
        }
        expect(policy_json).to eq(expected_policy)
      end

      it "excludes disallowed attributes" do
        allowed_keys = %w[minimum_character_length require_number_characters require_symbol_characters]
        excluded_keys = %w[
          disallow_common_passwords
          max_repeats
          max_sequence
          maximum_character_length
          maximum_login_attempts
        ]
        aggregate_failures "validating included and excluded attributes" do
          expect(policy_json.keys).to match_array(allowed_keys)
          excluded_keys.each { |key| expect(policy_json).not_to have_key(key) }
        end
      end

      it "does not contain unexpected attributes" do
        unexpected_keys = policy_json.keys - %w[minimum_character_length require_number_characters require_symbol_characters]
        expect(unexpected_keys).to be_empty, "Unexpected keys found: #{unexpected_keys.join(", ")}"
      end
    end

    context "when unset" do
      before { allow(account).to receive(:password_policy).and_return(nil) }

      it "does not include the data-password-policy attribute" do
        expect(login_data.attributes).not_to include("data-password-policy")
      end
    end

    context "when empty" do
      before { allow(account).to receive(:password_policy).and_return({}) }

      it "does not include the data-password-policy attribute" do
        expect(login_data.attributes).not_to include("data-password-policy")
      end
    end
  end

  describe "xss and weird character handling" do
    let(:xss_string)             { %{" onmouseover="alert('xss')} }
    let(:xss_string_with_script) { "<script>alert('xss')</script>" }
    let(:weird_unicode)          { "string with 𝒲𝒺𝒾𝓇𝒹 chars 💣" }

    before do
      allow(view).to receive(:brand_variable)
        .with("ic-brand-Login-logo")
        .and_return("https://cdn.canvas.com/accounts/1/files/1/download?verifier=abc123")
      allow(account).to receive_messages(
        login_handle_name_with_inference: xss_string,
        short_name: "#{xss_string_with_script} #{weird_unicode}"
      )
      allow(view).to receive_messages(
        help_link_name: xss_string_with_script,
        help_link_data: {
          "track-category": "category",
          "track-label": "label"
        }
      )
      render template: "login/canvas/new_login"
    end

    it "renders the login data div" do
      expect(rendered_page.at_css("#new_login_data")).to be_present, "Expected #new_login_data div to be present in rendered HTML"
    end

    it "escapes login_handle_name to prevent HTML/script injection" do
      # check raw HTML escaping since Nokogiri auto-decodes attribute values
      attr_value = rendered[/data-login-handle-name="([^"]+)"/, 1]
      aggregate_failures "HTML escaping for data-login-handle-name" do
        expect(attr_value).to be_present
        expect(attr_value).to include("&quot;"), "Expected double quotes to be escaped"
        expect(attr_value).not_to include("<"), "Raw '<' should not appear"
        expect(attr_value).not_to include(">"), "Raw '>' should not appear"
        # un-escaping should yield the original input, confirming only HTML entity escaping
        expect(CGI.unescapeHTML(attr_value)).to eq(xss_string), "Expected unescaped data-login-handle-name to match original xss_string input"
      end
    end

    it "escapes help_link JSON to prevent HTML injection" do
      raw_attr = rendered[/data-help-link="([^"]+)"/, 1]
      aggregate_failures "help_link data-* escaping and decoding" do
        expect(raw_attr).to be_present, "Expected data-help-link to be present in rendered HTML"
        expect(raw_attr).to include("&quot;"), "Expected escaped double quotes (&quot;) in attribute value"
        expect(raw_attr).not_to include("<"), "Raw '<' should not appear in the attribute value"
        expect(raw_attr).not_to include(">"), "Raw '>' should not appear in the attribute value"
        decoded_json = CGI.unescapeHTML(raw_attr)
        expect(decoded_json).not_to include("<script>"), "Decoded help_link JSON should not contain raw script tags"
        parsed = JSON.parse(decoded_json)
        expect(parsed["text"]).to eq(xss_string_with_script), "Expected JSON 'text' value to match xss_string_with_script"
        expect(parsed["trackCategory"]).to eq("category"), "Expected JSON trackCategory to match"
        expect(parsed["trackLabel"]).to eq("label"), "Expected JSON trackLabel to match"
      end
    end

    it "renders short_name safely in visible HTML, escaping scripts and preserving unicode" do
      escaped_short_name = CGI.escapeHTML(xss_string_with_script)
      aggregate_failures "short_name output safety" do
        expect(rendered).to include(escaped_short_name), "Expected HTML to contain escaped short_name"
        expect(rendered).not_to include(xss_string_with_script), "Expected raw <script> to be escaped"
        expect(rendered).to include(weird_unicode), "Expected weird unicode characters to be preserved in rendered output"
      end
    end

    it "does not render unexpected attributes like onmouseover in the login data div" do
      node = rendered_page.at_css("#new_login_data")
      aggregate_failures "unexpected attribute checks" do
        expect(node).to be_present, "Expected #new_login_data div to be present in rendered HTML"
        expect(node.attribute_nodes.map(&:name)).not_to include("onmouseover"), "Expected no injected attributes like 'onmouseover' on #new_login_data"
      end
    end
  end
end
