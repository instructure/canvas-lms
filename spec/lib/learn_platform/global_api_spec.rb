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

describe LearnPlatform::GlobalApi do
  describe ".credentials" do
    subject { described_class.credentials }

    before { described_class.instance_variable_set(:@credentials, nil) }

    context "when creds are configured" do
      let(:fake_secrets) do
        {
          service_name: "interop",
          service_secret: "test_secret",
        }.with_indifferent_access
      end

      before do
        allow(Rails.application.credentials).to receive(:learn_platform_creds).and_return(fake_secrets)
      end

      it "reads from Vault" do
        expect(subject).to eq(fake_secrets)
      end
    end

    context "when creds are not configured" do
      before do
        allow(Rails.application.credentials).to receive(:learn_platform_creds).and_return(nil)
      end

      it "returns empty hash" do
        expect(subject).to eq({})
      end
    end
  end

  describe ".auth_headers" do
    subject { described_class.auth_headers }

    let(:fake_secrets) do
      {
        service_name: "interop",
        service_secret: "test_secret",
        learn_platform_basic_token: "basic_auth_token"
      }.with_indifferent_access
    end

    before do
      described_class.instance_variable_set(:@credentials, nil)
      described_class.instance_variable_set(:@jwt, nil)
      allow(Rails.application.credentials).to receive(:learn_platform_creds).and_return(fake_secrets)
    end

    context "when use_jwt_auth_for_utid_sync feature flag is enabled" do
      before do
        Account.site_admin.enable_feature!(:use_jwt_auth_for_utid_sync)
      end

      it "returns JWT bearer token in Authorization header" do
        headers = subject
        expect(headers[:Authorization]).to match(/^Bearer /)

        # Verify it's a valid JWT
        token = headers[:Authorization].sub(/^Bearer /, "")
        decoded = JSON::JWT.decode(token, "test_secret")
        expect(decoded[:iss]).to eq("interop")
        expect(decoded[:exp]).to be_within(5).of(Time.now.to_i + 300)
      end
    end

    context "when use_jwt_auth_for_utid_sync feature flag is disabled" do
      before do
        Account.site_admin.disable_feature!(:use_jwt_auth_for_utid_sync)
      end

      it "returns Basic auth token in Authorization header" do
        expect(subject).to eq({ Authorization: "Basic basic_auth_token" })
      end
    end
  end

  describe ".config" do
    subject { described_class.config }

    let(:config_values) { raise "configure in examples" }
    let(:fake_config) { DynamicSettings::FallbackProxy.new(config_values) }

    before do
      described_class.instance_variable_set(:@config, nil)
      allow(DynamicSettings).to receive(:find).with("learn_platform_global_api", service: "canvas").and_return(fake_config)
    end

    context "when Consul is populated" do
      let(:config_values) do
        {
          url: "https://example.com",
          enabled_for_canvas: true,
        }
      end

      it "reads from Consul" do
        expect(subject).to eq(fake_config)
      end
    end

    context "when Consul is not populated" do
      let(:config_values) { {} }

      it "returns empty DynamicSettings hash" do
        expect(subject).to eq(fake_config)
      end
    end
  end

  describe ".endpoint" do
    subject { described_class.endpoint }

    let(:url) { "https://example.com" }

    before do
      described_class.instance_variable_set(:@config, nil)
      described_class.instance_variable_set(:@endpoint, nil)
    end

    context "when endpoint is configured" do
      before do
        allow(DynamicSettings).to receive(:find).with("learn_platform_global_api", service: "canvas").and_return({ url: })
      end

      it "reads from Consul" do
        expect(subject).to eq(url)
      end

      context "when there is an extra '/'" do
        let(:url) { "https://example.com/" }

        it "chomps it off" do
          expect(subject).to eq("https://example.com")
        end
      end
    end

    context "when endpoint is not configured" do
      before do
        allow(DynamicSettings).to receive(:find).with("learn_platform_global_api", service: "canvas").and_return({})
      end

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  describe ".enabled?" do
    subject { described_class.enabled? }

    before do
      described_class.instance_variable_set(:@config, nil)
    end

    context "when enabled is set in Consul" do
      before do
        allow(DynamicSettings).to receive(:find).with("learn_platform_global_api", service: "canvas").and_return({ enabled_for_canvas: true })
      end

      it { is_expected.to be_truthy }
    end

    context "when Consul is not configured" do
      before do
        allow(DynamicSettings).to receive(:find).with("learn_platform_global_api", service: "canvas").and_return({})
      end

      it { is_expected.to be_falsy }
    end
  end

  describe ".get_unified_tool_id" do
    subject do
      described_class.get_unified_tool_id(
        lti_name:,
        lti_tool_id:,
        lti_domain:,
        lti_version:,
        lti_url:,
        integration_type:,
        lti_redirect_url:
      )
    end

    let(:lti_name) { "Lti Tool Name" }
    let(:lti_tool_id) { "redirect" }
    let(:lti_domain) { "www.example.com" }
    let(:lti_version) { "1.3" }
    let(:lti_url) { "http://www.tool.com/launch" }
    let(:integration_type) { "TBD" }
    let(:lti_redirect_url) { "http://example.com" }
    let(:unified_tool_id) { "uti-1234" }
    let(:success_response) { Net::HTTPSuccess.new(Net::HTTPOK, "200", "OK") }
    let(:fake_secrets) do
      {
        service_name: "interop",
        service_secret: "test_secret",
      }.with_indifferent_access
    end

    before do
      allow(Rails.application.credentials).to receive(:learn_platform_creds).and_return(fake_secrets)
      allow(CanvasHttp).to receive(:get).and_return(success_response)
      allow(success_response).to receive(:body).and_return({ unified_tool_id: }.to_json)
      allow(LearnPlatform::GlobalApi).to receive(:enabled?).and_return(true)
    end

    %w[lti_name lti_tool_id lti_domain lti_version lti_url integration_type lti_redirect_url].each do |param|
      it "is sending the #{param} GET parameter" do
        expect(CanvasHttp).to receive(:get).with(/#{param}=/, anything)
        subject
      end
    end

    context "with successful response" do
      it "returns unified_tool_id" do
        expect(subject).to eq(unified_tool_id)
      end
    end
  end

  describe ".jwt" do
    let(:fake_secrets) do
      {
        service_name: "interop",
        service_secret: "test_secret",
      }.with_indifferent_access
    end

    before do
      described_class.instance_variable_set(:@credentials, nil)
      described_class.instance_variable_set(:@jwt, nil)
      allow(Rails.application.credentials).to receive(:learn_platform_creds).and_return(fake_secrets)
    end

    it "generates a signed JWT using the secret" do
      jwt = described_class.jwt
      expect(jwt).to be_present

      expect { jwt.verify!(fake_secrets[:service_secret]) }.not_to raise_error
      expect(jwt[:iss]).to eq("interop")
      expect(jwt[:exp]).to be_within(1.second).of(5.minutes.from_now.to_i)
    end

    it "reuses existing JWT when it expires in more than 1 minute" do
      Timecop.freeze do
        first_jwt = described_class.jwt
        second_jwt = described_class.jwt
        expect(first_jwt).to eq(second_jwt)
      end
    end

    it "does not regenerate JWT when it expires in exactly 61 seconds" do
      Timecop.freeze do
        first_jwt = described_class.jwt

        Timecop.freeze((3.minutes + 59.seconds).from_now.to_time) do
          second_jwt = described_class.jwt
          expect(second_jwt).to eql(first_jwt)
        end
      end
    end

    it "regenerates JWT when it expires in less than 1 minute" do
      Timecop.freeze do
        first_jwt = described_class.jwt
        Timecop.freeze((4.minutes + 1.second).from_now.to_time) do # JWT expires in 59 seconds
          second_jwt = described_class.jwt
          expect(second_jwt).not_to eq(first_jwt)

          expect(second_jwt["exp"] > first_jwt["exp"]).to be true
        end
      end
    end

    it "regenerates JWT when it expires in exactly 60 seconds" do
      first_jwt = nil

      Timecop.freeze do
        first_jwt = described_class.jwt
      end

      Timecop.freeze(4.minutes.from_now) do # JWT expires in exactly 60 seconds
        second_jwt = described_class.jwt
        expect(second_jwt).not_to eq(first_jwt)

        expect(second_jwt["exp"] > first_jwt["exp"]).to be true
      end
    end

    it "regenerates JWT when it has already expired" do
      first_jwt = nil

      Timecop.freeze do
        first_jwt = described_class.jwt
      end

      Timecop.freeze(6.minutes.from_now) do # JWT has expired
        second_jwt = described_class.jwt
        expect(second_jwt).not_to eq(first_jwt)
      end
    end

    it "regenerates JWT when cached JWT is nil" do
      first_jwt = nil
      second_jwt = nil

      Timecop.freeze do
        described_class.instance_variable_set(:@jwt, nil)
        first_jwt = described_class.jwt
        expect(first_jwt).to be_present
      end

      # Travel forward in time to ensure exp timestamp is different
      Timecop.freeze(1.second.from_now) do
        described_class.instance_variable_set(:@jwt, nil)
        second_jwt = described_class.jwt
        expect(second_jwt).to be_present
        expect(second_jwt).not_to eq(first_jwt)
      end
    end
  end

  describe ".post_unified_tool_id_bulk_load_callback" do
    include WebMock::API

    before do
      allow(described_class).to receive_messages(credentials: { service_name: "interop", service_secret: "test_secret" }, endpoint: "https://fakelearnplatform.instructure.com")
    end

    let(:callback_url) do
      "https://fakelearnplatform.instructure.com/api/v2/lti/unified_tool_id_bulk_load"
    end

    let(:payload) do
      {
        id: "foo",
        region: "us-east-1",
        row_stats: { "total" => 1, "shard_failed" => 1 },
        shard_issues: { "failed" => [1] },
        error: { "code" => "waz" },
      }
    end

    it "hits the LearnPlatform callback URL and returns the response" do
      stubbed = stub_request(:post, callback_url).with do |req|
        expect(req.headers["Content-Type"]).to eq("application/json")
        expect(req.headers["Authorization"]).to match(/^Bearer /)
        expect(JSON.parse(req.body)).to eq(payload.transform_keys(&:to_s))
      end.to_return(status: 200)

      result = described_class.post_unified_tool_id_bulk_load_callback(**payload)
      assert_requested(stubbed)
      expect(result).to be_a(Net::HTTPOK)
    end

    it "raises CanvasHttp::InvalidResponseCodeError if a non-2xx status is returned" do
      stubbed = stub_request(:post, callback_url).to_return(status: 429)
      expect do
        described_class.post_unified_tool_id_bulk_load_callback(**payload)
      end.to raise_error(CanvasHttp::InvalidResponseCodeError)
      assert_requested(stubbed)
    end
  end
end
