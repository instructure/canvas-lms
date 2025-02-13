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
          learn_platform_basic_token: "learn_platform_secret",
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

    before do
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

  describe ".post_unified_tool_id_bulk_load_callback" do
    include WebMock::API

    before do
      allow(described_class).to receive_messages(credentials: { learn_platform_basic_token: "fake-auth" }, endpoint: "https://fakelearnplatform.instructure.com")
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
        expect(req.headers["Authorization"]).to eq("Basic fake-auth")
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
