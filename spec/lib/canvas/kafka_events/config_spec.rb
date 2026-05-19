# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

describe Canvas::KafkaEvents::Config do
  subject(:config) { described_class.new }

  let(:fake_settings) { double }

  before do
    allow(DynamicSettings).to receive(:find).and_call_original
    allow(DynamicSettings).to receive(:find).with(tree: :private).and_return(fake_settings)
    allow(fake_settings).to receive(:[]).and_return(nil)
    allow(Rails.application.credentials).to receive(:kafka_events).and_return(nil)
  end

  def stub_consul(**yml)
    allow(fake_settings).to receive(:[]).with("kafka_events.yml", anything).and_return(YAML.dump(yml.transform_keys(&:to_s)))
  end

  def stub_credentials(**bundle)
    allow(Rails.application.credentials).to receive(:kafka_events).and_return(bundle.with_indifferent_access)
  end

  describe "loading at construction" do
    it "reads Consul for operational settings and credentials for connection" do
      stub_consul(
        client_id: "canvas-edge",
        topics: { "course_events" => "course.events" }
      )
      stub_credentials(brokers: "b-1.example.com:9094", sasl_username: "canvas")

      expect(config.brokers).to eql("b-1.example.com:9094")
      expect(config.sasl_username).to eql("canvas")
      expect(config.client_id).to eql("canvas-edge")
      expect(config.topic_for("course_events")).to eql("course.events")
    end

    it "returns empty state when the operational settings lookup raises" do
      allow(DynamicSettings).to receive(:find).with(tree: :private).and_raise(StandardError, "consul down")
      expect(Rails.logger).to receive(:warn).with(/Kafka operational settings load error: consul down/)
      expect(config.topic_for("course_events")).to be_nil
    end

    it "returns empty state when credentials are missing" do
      allow(Rails.application.credentials).to receive(:kafka_events).and_return(nil)
      expect(config.brokers).to be_nil
    end

    it "returns empty state when Consul returns yaml that doesn't parse to a Hash" do
      allow(fake_settings).to receive(:[]).with("kafka_events.yml", anything).and_return("just a bare string")
      expect(config.topic_for("course_events")).to be_nil
    end
  end

  describe "defaults" do
    it "applies defaults when nothing is configured" do
      expect(config.security_protocol).to eql("SASL_SSL")
      expect(config.sasl_mechanism).to eql("PLAIN")
      expect(config.client_id).to eql("canvas")
      expect(config.message_timeout_ms).to be(300_000)
      expect(config.queue_buffering_max_messages).to be(100_000)
      expect(config.reconnect_backoff_ms).to be(100)
      expect(config.reconnect_backoff_max_ms).to be(10_000)
    end

    it "allows credentials to override protocol and mechanism" do
      stub_credentials(brokers: "b:9094", security_protocol: "PLAINTEXT", sasl_mechanism: "SCRAM-SHA-512")
      expect(config.security_protocol).to eql("PLAINTEXT")
      expect(config.sasl_mechanism).to eql("SCRAM-SHA-512")
    end

    it "allows Consul to override tuning knobs" do
      stub_consul(
        client_id: "edge",
        message_timeout_ms: 5000,
        queue_buffering_max_messages: 50_000,
        reconnect_backoff_ms: 5_000,
        reconnect_backoff_max_ms: 60_000
      )
      expect(config.client_id).to eql("edge")
      expect(config.message_timeout_ms).to be(5000)
      expect(config.queue_buffering_max_messages).to be(50_000)
      expect(config.reconnect_backoff_ms).to be(5_000)
      expect(config.reconnect_backoff_max_ms).to be(60_000)
    end
  end

  describe "#brokers_configured?" do
    it "is false when brokers is blank" do
      expect(config.brokers_configured?).to be(false)
    end

    it "is true when brokers is set in credentials" do
      stub_credentials(brokers: "b.example.com:9094")
      expect(config.brokers_configured?).to be(true)
    end
  end

  describe "#sasl_configured?" do
    it "is true when sasl_username is present" do
      stub_credentials(brokers: "b:9094", sasl_username: "canvas", security_protocol: "PLAINTEXT")
      expect(config.sasl_configured?).to be(true)
    end

    it "is true when security_protocol is SASL_* even without a username" do
      stub_credentials(brokers: "b:9094", security_protocol: "SASL_SSL")
      expect(config.sasl_configured?).to be(true)
    end

    it "is false when security_protocol is PLAINTEXT and no username is set" do
      stub_credentials(brokers: "b:9094", security_protocol: "PLAINTEXT")
      expect(config.sasl_configured?).to be(false)
    end
  end

  describe "#sasl_credentials_complete?" do
    it "is true when both username and password are present" do
      stub_credentials(brokers: "b:9094", sasl_username: "canvas", sasl_password: "s3cret")
      expect(config.sasl_credentials_complete?).to be(true)
    end

    it "is false when only username is present" do
      stub_credentials(brokers: "b:9094", sasl_username: "canvas")
      expect(config.sasl_credentials_complete?).to be(false)
    end

    it "is false when only password is present" do
      stub_credentials(brokers: "b:9094", sasl_password: "s3cret")
      expect(config.sasl_credentials_complete?).to be(false)
    end
  end

  describe "#kafka_options" do
    it "builds the hash with stringified timeouts and omits nil keys" do
      stub_credentials(brokers: "b:9094", sasl_username: "canvas", sasl_password: "secret")
      stub_consul(message_timeout_ms: 5000)

      opts = config.kafka_options
      expect(opts[:"bootstrap.servers"]).to eql("b:9094")
      expect(opts[:"security.protocol"]).to eql("SASL_SSL")
      expect(opts[:"sasl.mechanisms"]).to eql("PLAIN")
      expect(opts[:"sasl.username"]).to eql("canvas")
      expect(opts[:"sasl.password"]).to eql("secret")
      expect(opts[:"client.id"]).to eql("canvas")
      expect(opts[:"message.timeout.ms"]).to eql("5000")
      expect(opts[:"queue.buffering.max.messages"]).to eql("100000")
      expect(opts[:"reconnect.backoff.ms"]).to eql("100")
      expect(opts[:"reconnect.backoff.max.ms"]).to eql("10000")
    end

    it "sets durability, compression, and network defaults" do
      stub_credentials(brokers: "b:9094", security_protocol: "PLAINTEXT")

      opts = config.kafka_options
      expect(opts[:acks]).to eql("all")
      expect(opts[:"enable.idempotence"]).to eql("true")
      expect(opts[:"compression.type"]).to eql("zstd")
      expect(opts[:"socket.keepalive.enable"]).to eql("true")
      expect(opts[:"linger.ms"]).to eql("50")
    end

    it "omits SASL fields when not configured" do
      stub_credentials(brokers: "b:9094", security_protocol: "PLAINTEXT")

      opts = config.kafka_options
      expect(opts).not_to have_key(:"sasl.username")
      expect(opts).not_to have_key(:"sasl.password")
    end
  end

  describe "#validate!" do
    it "is a no-op when fully configured" do
      stub_credentials(brokers: "b:9094", security_protocol: "PLAINTEXT")
      stub_consul(topics: { "course_events" => "course.events" })

      expect { config.validate! }.not_to raise_error
    end

    it "raises ConfigError when sasl_username is set without sasl_password" do
      stub_credentials(brokers: "b:9094", sasl_username: "canvas")
      stub_consul(topics: { "course_events" => "course.events" })

      expect { config.validate! }.to raise_error(
        Canvas::KafkaEvents::Config::ConfigError,
        /requires both sasl_username and sasl_password/
      )
    end

    it "raises ConfigError when security_protocol is SASL_* but credentials are missing" do
      stub_credentials(brokers: "b:9094", security_protocol: "SASL_SSL")
      stub_consul(topics: { "course_events" => "course.events" })

      expect { config.validate! }.to raise_error(
        Canvas::KafkaEvents::Config::ConfigError,
        /requires both sasl_username and sasl_password/
      )
    end

    it "raises ConfigError listing every missing topic key" do
      stub_credentials(brokers: "b:9094", security_protocol: "PLAINTEXT")
      stub_consul(topics: {})

      expect { config.validate! }.to raise_error(
        Canvas::KafkaEvents::Config::ConfigError,
        /required topic\(s\) missing from DynamicSettings: course_events/
      )
    end
  end
end
