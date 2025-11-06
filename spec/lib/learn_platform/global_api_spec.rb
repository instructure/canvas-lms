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

    context "caching behavior" do
      it "caches successful responses for 5 minutes" do
        expect(CanvasHttp).to receive(:get).once.and_return(success_response)

        # First call should hit the API
        result1 = subject
        expect(result1).to eq(unified_tool_id)

        # Second call should use cache
        result2 = subject
        expect(result2).to eq(unified_tool_id)
      end

      it "caches null responses for 5 minutes" do
        allow(success_response).to receive(:body).and_return({ unified_tool_id: nil }.to_json)
        expect(CanvasHttp).to receive(:get).once.and_return(success_response)

        # First call should hit the API and return nil
        result1 = subject
        expect(result1).to be_nil

        # Second call should use cache and return nil
        result2 = subject
        expect(result2).to be_nil
      end

      it "caches error responses for 5 minutes" do
        error_response = Net::HTTPBadRequest.new(Net::HTTPBadRequest, "400", "Bad Request")
        expect(CanvasHttp).to receive(:get).once.and_return(error_response)

        # First call should hit the API and return false
        result1 = subject
        expect(result1).to be false

        # Second call should use cache and return false
        result2 = subject
        expect(result2).to be false
      end

      it "uses tool info as cache key" do
        # Different tool info should not use cached result
        expect(CanvasHttp).to receive(:get).twice.and_return(success_response)

        # First call with original params
        result1 = subject
        expect(result1).to eq(unified_tool_id)

        # Second call with different tool name should hit API again
        result2 = described_class.get_unified_tool_id(
          lti_name: "Different Tool Name",
          lti_tool_id:,
          lti_domain:,
          lti_version:,
          lti_url:,
          integration_type:,
          lti_redirect_url:
        )
        expect(result2).to eq(unified_tool_id)
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

  describe ".lookup_api_registrations" do
    subject { described_class.lookup_api_registrations(redirect_uris) }

    let(:redirect_uris) { ["https://example.com/redirect", "https://another.com/callback"] }
    let(:success_response) { Net::HTTPSuccess.new(Net::HTTPOK, "200", "OK") }
    let(:api_registrations) do
      [
        {
          unified_tool_id: "550e8400-e29b-41d4-a716-446655440000",
          global_product_id: "e8f9a0b1-c2d3-4567-e890-123456789abc",
          tool_name: "Math Learning Platform",
          tool_id: 789,
          company_id: 456,
          company_name: "Educational Tech Solutions",
          source: "partner_provided"
        },
        {
          unified_tool_id: "6ba7b810-9dad-11d1-80b4-00c04fd430c8",
          global_product_id: "d7e8f9a0-b1c2-4345-d678-90abcdef1234",
          tool_name: "Science Lab Simulator",
          tool_id: 321,
          company_id: 654,
          company_name: "STEM Education Corp",
          source: "manual"
        }
      ]
    end
    let(:fake_secrets) do
      {
        service_name: "interop",
        service_secret: "test_secret",
      }.with_indifferent_access
    end
    let(:endpoint) { "https://fakelearnplatform.instructure.com" }

    before do
      allow(Rails.application.credentials).to receive(:learn_platform_creds).and_return(fake_secrets)
      allow(CanvasHttp).to receive(:get).and_return(success_response)
      allow(success_response).to receive(:body).and_return({ api_registrations: }.to_json)
      allow(LearnPlatform::GlobalApi).to receive_messages(enabled?: true, endpoint:)
      allow(InstStatsd::Statsd).to receive(:distributed_increment).with(any_args).and_call_original
    end

    context "when enabled" do
      it "sends redirect_uris in the GET query parameters" do
        expect(CanvasHttp).to receive(:get).with(
          "#{endpoint}#{LearnPlatform::GlobalApi::GET_API_LOOKUP_ENDPOINT}?redirect_urls%5B%5D=https%3A%2F%2Fexample.com%2Fredirect&redirect_urls%5B%5D=https%3A%2F%2Fanother.com%2Fcallback&sources%5B%5D=partner_provided",
          anything
        )
        subject
      end

      context "with successful response" do
        it "returns array of api_registrations" do
          expect(subject).to eq(api_registrations)
        end

        it "increments success metric" do
          expect(InstStatsd::Statsd).to receive(:distributed_increment).with(
            "learn_platform_api.success",
            tags: { event_type: "lookup_api_registrations" }
          )
          subject
        end
      end

      context "with empty matches" do
        let(:api_registrations) { [] }

        it "returns empty array" do
          expect(subject).to eq([])
        end
      end

      context "with HTTP error response" do
        let(:error_response) { double(Net::HTTPBadRequest, code: "400", body: "Bad Request", is_a?: false) }

        before do
          allow(CanvasHttp).to receive(:get).and_return(error_response)
          allow(error_response).to receive(:code).and_return("400")
        end

        it "returns empty array" do
          expect(subject).to eq([])
        end

        it "increments error metric" do
          expect(InstStatsd::Statsd).to receive(:distributed_increment).with(
            "learn_platform_api.error.http_failure",
            tags: { event_type: "lookup_api_registrations", status_code: "400" }
          )
          subject
        end
      end

      context "with CanvasHttp error" do
        before do
          allow(CanvasHttp).to receive(:get).and_raise(CanvasHttp::Error)
        end

        it "returns empty array" do
          expect(subject).to eq([])
        end

        it "increments error metric" do
          expect(InstStatsd::Statsd).to receive(:distributed_increment).with(
            "learn_platform_api.error",
            tags: { event_type: "lookup_api_registrations" }
          )
          subject
        end
      end

      context "with invalid JSON response" do
        before do
          allow(success_response).to receive(:body).and_return("invalid json")
        end

        it "returns empty array" do
          expect(subject).to eq([])
        end

        it "increments error metric" do
          expect(InstStatsd::Statsd).to receive(:distributed_increment).with(
            "learn_platform_api.error",
            tags: { event_type: "lookup_api_registrations" }
          )
          subject
        end
      end
    end

    context "when not enabled" do
      before do
        allow(LearnPlatform::GlobalApi).to receive(:enabled?).and_return(false)
      end

      it "returns empty array without making request" do
        expect(CanvasHttp).not_to receive(:post)
        expect(subject).to eq([])
      end
    end

    context "when redirect_uris is empty" do
      let(:redirect_uris) { [] }

      it "returns empty array without making request" do
        expect(CanvasHttp).not_to receive(:post)
        expect(subject).to eq([])
      end
    end

    context "when redirect_uris is nil" do
      let(:redirect_uris) { nil }

      it "returns empty array without making request" do
        expect(CanvasHttp).not_to receive(:post)
        expect(subject).to eq([])
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
