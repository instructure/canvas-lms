# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

require_relative "../../../spec_helper"
require_relative "../../views_helper"

describe "login/otp/new" do
  let(:current_user) { double("User") }
  let(:current_pseudonym) { double("Pseudonym", unique_id: "unique_id_123") }
  let(:domain_root_account) { double("Account", name: "Domain Account") }
  let(:communication_channels) { double("CommunicationChannels", sms: sms_channels) }
  let(:sms_channels) { double("SmsChannels", unretired: unretired_channels) }
  let(:unretired_channels) { [double("Channel", path: "1234567890", id: 1)] }

  before do
    assign(:current_user, current_user)
    assign(:current_pseudonym, current_pseudonym)
    assign(:domain_root_account, domain_root_account)

    allow(current_user).to receive_messages(
      mfa_settings: :required,
      communication_channels:
    )
    allow(view).to receive_messages(
      configuring?: true,
      otp_in_us_region?: true,
      otp_via_sms_provider?: true,
      session: { pending_otp_secret_key: "123456" }
    )
  end

  context "configuring MFA" do
    it "displays MFA setup instructions" do
      render
      expect(rendered).not_to be_nil
      doc = Nokogiri::HTML5(rendered)
      expect(doc.text).to include("Multi-Factor Authentication (MFA) enhances security by requiring a physical device and your Canvas login password.")
    end
  end

  context "with verification code sent to mobile" do
    let(:cc) { double("CommunicationChannel") }

    before do
      assign(:cc, cc)
      allow(cc).to receive(:otp_impaired?).and_return(false)
    end

    it "displays message that verification code has been sent" do
      render
      expect(rendered).not_to be_nil
      doc = Nokogiri::HTML5(rendered)
      expect(doc.text).to include("Please enter the verification code sent to your mobile phone number.")
    end

    context "when experiencing issues with SMS provider" do
      before do
        allow(cc).to receive(:otp_impaired?).and_return(true)
      end

      it "displays a warning message" do
        render
        expect(rendered).not_to be_nil
        doc = Nokogiri::HTML5(rendered)
        expect(doc.text).to include("Please check your email if your SMS code does not arrive soon.")
      end
    end
  end

  context "without verification code sent to mobile" do
    it "displays message to enter the verification code from token" do
      render
      expect(rendered).not_to be_nil
      doc = Nokogiri::HTML5(rendered)
      expect(doc.text).to include("Please enter the verification code shown by your token.")
    end
  end

  it "displays the OTP login form" do
    render
    expect(rendered).not_to be_nil
    doc = Nokogiri::HTML5(rendered)
    expect(doc.css("form#login_form")).not_to be_empty
    expect(doc.css("form#login_form .ic-Form-control .ic-Input-group")).not_to be_empty
    expect(doc.text).to include("Verification Code")
    expect(doc.text).to include("Remember this computer")
  end

  context "when in US region" do
    it "displays SMS option" do
      render
      expect(rendered).not_to be_nil
      doc = Nokogiri::HTML5(rendered)
      expect(doc.css(".grid-row .col-xs-12.col-sm-12.col-md-6")).not_to be_empty
    end

    it "displays the additional SMS text" do
      render
      expect(rendered).not_to be_nil
      doc = Nokogiri::HTML5(rendered)
      expect(doc.text).to include("The device can be a code generator or a mobile phone that receives text messages.")
    end

    it "displays the authenticator app recommendation" do
      render
      expect(rendered).not_to be_nil
      doc = Nokogiri::HTML5(rendered)
      expect(doc.text).to include("Using an authenticator app is strongly recommended for enhanced security.")
    end
  end

  context "when not in US region" do
    before do
      allow(view).to receive(:otp_in_us_region?).and_return(false)
    end

    it "does not display SMS option" do
      render
      expect(rendered).not_to be_nil
      doc = Nokogiri::HTML5(rendered)
      expect(doc.css(".grid-row .col-xs-12.col-sm-12.col-md-6")).to be_empty
    end

    it "does not display the additional SMS text" do
      render
      expect(rendered).not_to be_nil
      doc = Nokogiri::HTML5(rendered)
      expect(doc.text).not_to include("This can be a device that can generate verification codes, or a mobile phone that can receive text messages.")
    end

    it "does not display the authenticator app recommendation" do
      render
      expect(rendered).not_to be_nil
      doc = Nokogiri::HTML5(rendered)
      expect(doc.text).not_to include("Using an authenticator app is strongly recommended for enhanced security.")
    end
  end
end
