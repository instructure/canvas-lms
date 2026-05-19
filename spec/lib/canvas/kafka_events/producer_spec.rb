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

require "waterdrop"

describe Canvas::KafkaEvents::Producer do
  # Build a Config double with sane defaults. Tests override specific fields
  # as needed via `.and_return` or by passing overrides.
  def fake_config(**overrides)
    defaults = {
      brokers: "b.example.com:9094",
      brokers_configured?: true,
      sasl_configured?: false,
      sasl_credentials_complete?: false,
      sasl_username: nil,
      sasl_password: nil,
      kafka_options: { "bootstrap.servers": "b.example.com:9094" },
      validate!: nil,
    }
    topics = overrides.delete(:topics) || { "course_events" => "course.events" }
    cfg = instance_double(Canvas::KafkaEvents::Config, **defaults, **overrides)
    allow(cfg).to receive(:topic_for) { |k| topics[k.to_s] }
    cfg
  end

  let(:subscribed_blocks) { {} }
  let(:monitor) do
    m = instance_double(WaterDrop::Instrumentation::Monitor)
    allow(m).to receive(:subscribe) { |event, &block| subscribed_blocks[event] = block }
    m
  end
  let(:inner_producer) do
    wd = instance_double(WaterDrop::Producer, produce_async: nil, close: nil)
    allow(wd).to receive(:monitor).and_return(monitor)
    wd
  end

  before do
    allow(WaterDrop::Producer).to receive(:new).and_return(inner_producer)
  end

  describe "construction" do
    it "calls config.validate! and propagates ConfigError when it raises" do
      cfg = fake_config
      allow(cfg).to receive(:validate!).and_raise(
        Canvas::KafkaEvents::Config::ConfigError, "some misconfiguration"
      )
      expect { described_class.new(cfg) }.to raise_error(
        Canvas::KafkaEvents::Config::ConfigError, "some misconfiguration"
      )
      expect(WaterDrop::Producer).not_to have_received(:new)
    end

    it "logs an info line listing every required topic when config is valid" do
      expect(Rails.logger).to receive(:info).with(
        /Kafka events producer ready: brokers=b.example.com:9094 course_events=course.events/
      )
      described_class.new(fake_config)
    end

    it "builds the underlying WaterDrop producer" do
      described_class.new(fake_config)
      expect(WaterDrop::Producer).to have_received(:new)
    end
  end

  describe "#produce" do
    subject(:producer) { described_class.new(fake_config) }

    it "resolves the topic from Config, serializes the payload, and forwards to WaterDrop" do
      producer.produce(topic_key: "course_events", key: "acct-uuid", payload: { hi: "there" })
      expect(inner_producer).to have_received(:produce_async).with(
        topic: "course.events",
        key: "acct-uuid",
        payload: '{"hi":"there"}'
      )
    end

    it "no-ops when the topic_key does not resolve to a configured topic" do
      producer.produce(topic_key: "bogus", key: "acct-uuid", payload: { hi: "there" })
      expect(inner_producer).not_to have_received(:produce_async)
    end

    it "logs and increments statsd on WaterDrop::Errors::ProduceError, without raising" do
      err = WaterDrop::Errors::ProduceError.new("boom")
      allow(inner_producer).to receive(:produce_async).and_raise(err)
      expect(Rails.logger).to receive(:error).with(/Kafka produce error on topic course.events/)
      allow(InstStatsd::Statsd).to receive(:distributed_increment)
      expect(InstStatsd::Statsd).to receive(:distributed_increment).with("kafka_events.produce_errors")

      expect do
        producer.produce(topic_key: "course_events", key: "k", payload: { a: 1 })
      end.not_to raise_error
    end

    it "also swallows ProducerClosedError" do
      err = WaterDrop::Errors::ProducerClosedError.new("closed")
      allow(inner_producer).to receive(:produce_async).and_raise(err)
      allow(InstStatsd::Statsd).to receive(:distributed_increment)
      expect { producer.produce(topic_key: "course_events", key: "k", payload: { a: 1 }) }.not_to raise_error
    end
  end

  describe "#close" do
    subject(:producer) { described_class.new(fake_config) }

    it "closes the underlying WaterDrop producer" do
      producer.close
      expect(inner_producer).to have_received(:close)
    end

    it "swallows and logs errors from the underlying close" do
      allow(inner_producer).to receive(:close).and_raise(StandardError, "boom")
      expect(Rails.logger).to receive(:warn).with(/Kafka producer close error: boom/)
      expect { producer.close }.not_to raise_error
    end
  end

  describe "error.occurred subscription" do
    it "subscribes a block that increments statsd and warns on delivery failures" do
      described_class.new(fake_config)
      block = subscribed_blocks["error.occurred"]
      expect(block).to be_a(Proc)

      allow(InstStatsd::Statsd).to receive(:distributed_increment)
      expect(InstStatsd::Statsd).to receive(:distributed_increment).with("kafka_events.delivery_errors")
      expect(Rails.logger).to receive(:warn).with(/Kafka delivery failed: something broke/)

      # In production WaterDrop hands the block a Karafka::Core::Monitoring::Event,
      # which supports `#[]` the same way a Hash does; a plain Hash is a
      # behaviorally-equivalent stand-in for this test.
      block.call({ error: StandardError.new("something broke") })
    end
  end
end
