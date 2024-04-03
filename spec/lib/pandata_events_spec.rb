# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

describe PandataEvents do
  describe ".credentials" do
    subject { described_class.credentials }

    before { described_class.instance_variable_set(:@credentials, nil) }

    context "when creds are configured" do
      let(:fake_secrets) do
        {
          canvas_key: "canvas_key",
          canvas_secret: "canvas_secret",
        }.with_indifferent_access
      end

      before do
        allow(Rails.application.credentials).to receive(:pandata_creds).and_return(fake_secrets)
      end

      it "reads from Vault" do
        expect(subject).to eq(fake_secrets)
      end
    end

    context "when creds are not configured" do
      before do
        allow(Rails.application.credentials).to receive(:pandata_creds).and_return(nil)
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
      allow(DynamicSettings).to receive(:find).with("pandata/events", service: "canvas").and_return(fake_config)
    end

    context "when Consul is populated" do
      let(:config_values) do
        {
          url: "https://example.com",
          enabled: true,
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
        allow(DynamicSettings).to receive(:find).with("pandata/events", service: "canvas").and_return({ url: })
      end

      it "reads from Consul" do
        expect(subject).to eq(url)
      end
    end

    context "when endpoint is not configured" do
      before do
        allow(DynamicSettings).to receive(:find).with("pandata/events", service: "canvas").and_return({})
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
        allow(DynamicSettings).to receive(:find).with("pandata/events", service: "canvas").and_return({ enabled_for_canvas: true })
      end

      it { is_expected.to be_truthy }
    end

    context "when Consul is not configured" do
      before do
        allow(DynamicSettings).to receive(:find).with("pandata/events", service: "canvas").and_return({})
      end

      it { is_expected.to be_falsy }
    end
  end

  describe ".send_event" do
    subject do
      described_class.send_event(event_type, data, for_user_id: sub)
      run_jobs
    end

    let(:data) { { hello: :world } }
    let(:sub) { 123 }
    let(:event_type) { "event_type" }

    before do
      allow(PandataEvents).to receive(:enabled?).and_return(enabled)
      allow(PandataEvents).to receive(:post_event)
    end

    context "when PandataEvents is enabled" do
      let(:enabled) { true }

      it "calls post_event in a thread" do
        subject
        expect(PandataEvents).to have_received(:post_event).with(event_type, data, sub)
      end
    end

    context "when PandataEvents is not enabled" do
      let(:enabled) { false }

      it "does nothing" do
        subject
        expect(PandataEvents).not_to have_received(:post_event)
      end
    end

    context "when thread fails" do
      let(:enabled) { true }

      before do
        allow(Thread).to receive(:new).and_raise(ThreadError)
        allow(InstStatsd::Statsd).to receive(:increment).and_return(nil)
      end

      it "logs to statsd" do
        subject
        expect(InstStatsd::Statsd).to have_received(:increment).with("pandata_events.error.queue_failure", tags: { event_type: })
      end

      it "swallows the error" do
        expect { subject }.not_to raise_error
      end
    end
  end

  describe ".post_event" do
    subject { described_class.send(:post_event, event_type, data, sub) }

    let(:data) { { hello: "world" }.with_indifferent_access }
    let(:sub) { 123 }
    let(:event_type) { "event_type" }
    let(:credentials) do
      {
        canvas_key: "CANVAS",
        canvas_secret: "secret",
        canvas_secret_alg: "HS256"
      }.with_indifferent_access
    end
    let(:endpoint) { "https://example.com" }
    let(:response) { Net::HTTPSuccess.new(Net::HTTPOK, "200", "OK") }

    before do
      allow(PandataEvents).to receive_messages(credentials:, endpoint:)
      allow(CanvasHttp).to receive(:post).and_return(response)
    end

    it "posts to the endpoint" do
      subject
      expect(CanvasHttp).to have_received(:post).with(endpoint, anything, anything)
    end

    it "structures event data correctly" do
      subject
      expect(CanvasHttp).to have_received(:post) do |_, _, options|
        body = JSON.parse(options[:body]).with_indifferent_access
        event = body[:events].first
        expect(event[:timestamp]).to be_present
        expect(event[:eventType]).to eq(event_type)
        expect(event[:appTag]).to eq(credentials[:canvas_key])
        expect(event[:properties].with_indifferent_access).to eq(data)
      end
    end

    it "includes the auth token" do
      subject
      expect(CanvasHttp).to have_received(:post) do |_, headers, _|
        expect { CanvasSecurity.decode_jwt(headers[:Authorization].split.last, [credentials[:canvas_secret]]) }.not_to raise_error
      end
    end

    context "with successful response" do
      it "returns true" do
        expect(subject).to be_truthy
      end
    end

    context "with unsuccessful response" do
      let(:response) { double("response", code: 500, body: "uh oh!") }

      before do
        allow(CanvasHttp).to receive(:post).and_return(response)
        allow(InstStatsd::Statsd).to receive(:increment).and_return(nil)
      end

      it "returns false" do
        expect(subject).to be_falsy
      end

      it "logs to statsd" do
        subject
        expect(InstStatsd::Statsd).to have_received(:increment).with("pandata_events.error.http_failure", tags: { event_type:, status_code: response.code })
      end
    end

    context "with CanvasHttp error" do
      let(:exception) { CanvasHttp::Error.new("uh oh!") }

      before do
        allow(CanvasHttp).to receive(:post).and_raise(exception)
        allow(InstStatsd::Statsd).to receive(:increment).and_return(nil)
      end

      it "returns false" do
        expect(subject).to be_falsy
      end

      it "logs to statsd" do
        subject
        expect(InstStatsd::Statsd).to have_received(:increment).with("pandata_events.error", tags: { event_type: })
      end
    end
  end
end
