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

require_relative "../../spec_helper"

describe Login::OtpHelper do
  let(:dummy_class) { Class.new { include Login::OtpHelper } }
  let(:dummy_instance) { dummy_class.new }
  let(:session) { {} }
  let(:pseudonym) { double("Pseudonym") }
  let(:authentication_provider) { double("AuthenticationProvider", otp_via_sms?: true) }
  let(:account) { double("Account", canvas_authentication?: true, canvas_authentication_provider: authentication_provider) }
  let(:region) { "us-west-2" }

  # create a stubbed database server with a region
  def stub_database_server(region)
    database_server = double("database_server")
    allow(database_server).to receive(:region).and_return(region)
    database_server
  end

  before do
    allow(dummy_instance).to receive(:session).and_return(session)
    dummy_instance.instance_variable_set(:@current_pseudonym, pseudonym)
    allow(pseudonym).to receive_messages(authentication_provider:, account:)

    shard = double("Shard")
    allow(Shard).to receive(:current).and_return(shard)
    allow(shard).to receive(:database_server).and_return(stub_database_server(region))
  end

  describe "#configuring?" do
    context "when session[:pending_otp_secret_key] is set" do
      it "returns true" do
        session[:pending_otp_secret_key] = "some_secret_key"
        expect(dummy_instance.configuring?).to be_truthy
      end
    end

    context "when session[:pending_otp_secret_key] is not set" do
      it "returns false" do
        expect(dummy_instance.configuring?).to be_falsey
      end
    end
  end

  describe "#otp_via_sms_provider?" do
    context "when authentication_provider supports otp_via_sms" do
      it "returns true" do
        expect(dummy_instance.send(:otp_via_sms_provider?)).to be_truthy
      end
    end

    context "when neither authentication_provider nor canvas_authentication supports otp_via_sms" do
      it "returns false" do
        allow(authentication_provider).to receive(:otp_via_sms?).and_return(false)
        allow(account).to receive(:canvas_authentication?).and_return(false)
        expect(dummy_instance.send(:otp_via_sms_provider?)).to be_falsey
      end
    end
  end

  describe "#otp_via_sms_in_us_region?" do
    context "when authentication_provider supports otp_via_sms and region is in the US" do
      it "returns true" do
        expect(dummy_instance.otp_via_sms_in_us_region?).to be_truthy
      end
    end

    context "when authentication_provider does not support otp_via_sms but region is in the US" do
      it "returns false" do
        allow(authentication_provider).to receive(:otp_via_sms?).and_return(false)
        expect(dummy_instance.otp_via_sms_in_us_region?).to be_falsey
      end
    end

    context "when authentication_provider supports otp_via_sms but region is not in the US" do
      let(:region) { "eu-central-1" }

      it "returns false" do
        expect(dummy_instance.otp_via_sms_in_us_region?).to be_falsey
      end
    end

    context "when authentication_provider does not support otp_via_sms and region is not in the US" do
      let(:region) { "eu-central-1" }

      it "returns false" do
        allow(authentication_provider).to receive(:otp_via_sms?).and_return(false)
        expect(dummy_instance.otp_via_sms_in_us_region?).to be_falsey
      end
    end

    context "when region is nil" do
      let(:region) { nil }

      it "returns false" do
        expect(dummy_instance.otp_via_sms_in_us_region?).to be_falsey
      end
    end
  end

  describe "#otp_in_us_region?" do
    context "when region starts with 'us-'" do
      let(:region) { "us-west-2" }

      it "returns true" do
        expect(dummy_instance.send(:otp_in_us_region?)).to be_truthy
      end
    end

    context "when region does not start with 'us-'" do
      let(:region) { "eu-central-1" }

      it "returns false" do
        expect(dummy_instance.send(:otp_in_us_region?)).to be_falsey
      end
    end

    context "when region is nil" do
      let(:region) { nil }

      it "returns false" do
        expect(dummy_instance.send(:otp_in_us_region?)).to be_falsey
      end
    end
  end
end
