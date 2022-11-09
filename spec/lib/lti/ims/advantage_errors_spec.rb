# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

describe "LTI Advantage Errors" do
  shared_examples "error check" do
    it "initializes with default api message and http status code" do
      error = described_class.new
      expect(error.message).to eq("#{described_class} :: #{default_api_message}")
      expect(error.api_message).to eq(default_api_message)
      expect(error.status_code).to eq(default_status_code)
    end

    it "supports override of api message and http status code" do
      error = described_class.new(nil, api_message: "api_message override", status_code: :status_code_override)
      expect(error.message).to eq("#{described_class} :: api_message override")
      expect(error.api_message).to eq("api_message override")
      expect(error.status_code).to eq(:status_code_override)
    end

    it "supports override of message along with api message and http status code" do
      error = described_class.new("message override", api_message: "api_message override", status_code: :status_code_override)
      expect(error.message).to eq("message override :: api_message override")
      expect(error.api_message).to eq("api_message override")
      expect(error.status_code).to eq(:status_code_override)
    end

    it "suppresses duplicate message and api message" do
      error = described_class.new(
        "this value should only occur once in message",
        api_message: "this value should only occur once in message"
      )
      expect(error.message).to eq("this value should only occur once in message")
      expect(error.api_message).to eq("this value should only occur once in message")
    end

    it "preserves arbitrary options" do
      error = described_class.new(
        "message override",
        api_message: "api_message override",
        status_code: :status_code_override,
        arbitrary_option_name_1: :arbitrary_option_value_1
      )
      expect(error.message).to eq("message override :: api_message override")
      expect(error.api_message).to eq("api_message override")
      expect(error.status_code).to eq(:status_code_override)
      expect(error.opts[:api_message]).to eq("api_message override")
      expect(error.opts[:status_code]).to eq(:status_code_override)
      expect(error.opts[:arbitrary_option_name_1]).to eq(:arbitrary_option_value_1)
    end

    it "supports idiomatic raise usage" do
      raise described_class, "message override"
    rescue described_class => e
      expect(e.message).to eq("message override :: #{default_api_message}")
      expect(e.api_message).to eq(default_api_message)
      expect(e.status_code).to eq(default_status_code)
    end
  end

  describe Lti::IMS::AdvantageErrors::AdvantageServiceError do
    let(:default_api_message) { "Failed LTI Advantage service invocation" }
    let(:default_status_code) { :internal_server_error }

    it_behaves_like "error check"
  end

  describe Lti::IMS::AdvantageErrors::AdvantageClientError do
    let(:default_api_message) { "Invalid LTI Advantage service invocation" }
    let(:default_status_code) { :bad_request }

    it_behaves_like "error check"
  end

  describe Lti::IMS::AdvantageErrors::InvalidLaunchError do
    let(:default_api_message) { "Invalid LTI launch attempt" }
    let(:default_status_code) { :bad_request }

    it_behaves_like "error check"
  end

  describe Lti::IMS::AdvantageErrors::AdvantageSecurityError do
    let(:default_api_message) { "Service invocation refused" }
    let(:default_status_code) { :unauthorized }

    it_behaves_like "error check"
  end

  describe Lti::IMS::AdvantageErrors::InvalidAccessToken do
    let(:default_api_message) { "Invalid access token" }
    let(:default_status_code) { :unauthorized }

    it_behaves_like "error check"
  end

  describe Lti::IMS::AdvantageErrors::InvalidAccessTokenSignature do
    let(:default_api_message) { "Invalid access token signature" }
    let(:default_status_code) { :unauthorized }

    it_behaves_like "error check"
  end

  describe Lti::IMS::AdvantageErrors::InvalidAccessTokenSignatureType do
    let(:default_api_message) { "Access token signature algorithm not allowed" }
    let(:default_status_code) { :unauthorized }

    it_behaves_like "error check"
  end

  describe Lti::IMS::AdvantageErrors::MalformedAccessToken do
    let(:default_api_message) { "Invalid access token format" }
    let(:default_status_code) { :unauthorized }

    it_behaves_like "error check"
  end

  describe Lti::IMS::AdvantageErrors::InvalidAccessTokenClaims do
    let(:default_api_message) { "Access token contains invalid claims" }
    let(:default_status_code) { :unauthorized }

    it_behaves_like "error check"
  end

  describe Lti::IMS::AdvantageErrors::InvalidResourceLinkIdFilter do
    let(:default_api_message) { "Invalid 'rlid' parameter" }
    let(:default_status_code) { :bad_request }

    it_behaves_like "error check"
  end

  describe "base error rescue sanity check" do
    it "rescue of base service error type catches error subtypes" do
      # Borderline test of core ruby behavior, but we still want at least a sanity check that the basics of the
      # custom LTI Advantage error hierarchy work as expected, so we pick a rando error type at the bottom
      # of that tree and see if we can rescue it specifying a type at the top of that tree. (This is basically what
      # LTI Advantage controllers are expected to do.)

      raise Lti::IMS::AdvantageErrors::InvalidAccessTokenClaims, "message override"
    rescue Lti::IMS::AdvantageErrors::AdvantageServiceError => e
      expect(e.message).to eq("message override :: Access token contains invalid claims")
      expect(e.api_message).to eq("Access token contains invalid claims")
      expect(e.status_code).to eq(:unauthorized)
    end
  end
end
