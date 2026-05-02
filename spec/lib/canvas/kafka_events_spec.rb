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

describe Canvas::KafkaEvents do
  let(:fake_producer_class) do
    Class.new do
      attr_reader :produced

      def initialize
        @produced = []
      end

      def produce(topic_key:, key:, payload:)
        @produced << { topic_key:, key:, payload: }
      end
    end
  end

  let(:fake_producer) { fake_producer_class.new }
  let(:root_account) { Account.default }
  let(:course) { course_model(account: root_account) }
  let(:user) { user_model }

  def enable_all_gates
    Account.site_admin.enable_feature!(:enable_kafka_events)
    root_account.enable_feature!(:horizon_autopilot)
    allow(CanvasCareer::ExperienceResolver).to receive(:career_affiliated_institution?).with(root_account).and_return(true)
  end

  describe ".post_event" do
    let(:occurred_at) { Time.zone.parse("2024-04-17T12:00:00Z") }

    def post_course_completed(**overrides)
      described_class.post_event(
        Canvas::KafkaEvents::Events::COURSE_COMPLETED,
        root_account:,
        user:,
        payload: { course_id: course.global_id.to_s },
        occurred_at:,
        **overrides
      )
    end

    around do |example|
      prev = Canvas::KafkaEvents.producer
      Canvas::KafkaEvents.producer = fake_producer
      example.run
    ensure
      Canvas::KafkaEvents.producer = prev
    end

    before do
      enable_all_gates
    end

    it "produces an event when all gates pass" do
      post_course_completed

      expect(fake_producer.produced.length).to be(1)
      record = fake_producer.produced.first
      expect(record[:topic_key]).to eql("course_events")
      expect(record[:key]).to eql(root_account.uuid)

      env = record[:payload]
      expect(env[:event_type]).to eql("canvas.course.completed")
      expect(env[:root_account_uuid]).to eql(root_account.uuid)
      expect(env[:user_uuid]).to eql(user.uuid)
      expect(env[:course_id]).to eql(course.global_id.to_s)
      expect(env[:timestamp]).to eql("2024-04-17T12:00:00.000Z")
      expect(env[:event_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it "does not allow payload keys to overwrite reserved envelope keys" do
      described_class.post_event(
        Canvas::KafkaEvents::Events::COURSE_COMPLETED,
        root_account:,
        user:,
        payload: {
          event_id: "attacker-supplied",
          user_uuid: "attacker-supplied",
          timestamp: "attacker-supplied",
          course_id: course.global_id.to_s
        },
        occurred_at:
      )

      env = fake_producer.produced.first[:payload]
      expect(env[:event_id]).to match(/\A[0-9a-f-]{36}\z/)
      expect(env[:user_uuid]).to eql(user.uuid)
      expect(env[:timestamp]).to eql("2024-04-17T12:00:00.000Z")
      expect(env[:course_id]).to eql(course.global_id.to_s)
    end

    it "defaults timestamp to now when occurred_at is nil" do
      freeze_time = Time.zone.parse("2024-04-17T18:30:00Z")
      Timecop.freeze(freeze_time) do
        post_course_completed(occurred_at: nil)
      end

      env = fake_producer.produced.first[:payload]
      expect(env[:timestamp]).to eql(freeze_time.utc.iso8601(3))
    end

    it "no-ops when the passed value is not a Canvas::KafkaEvents::Event" do
      described_class.post_event(
        "course_completed", # bare string, not the COURSE_COMPLETED constant
        root_account:,
        user:,
        payload: {}
      )
      expect(fake_producer.produced).to be_empty
    end

    it "no-ops when the root account is not a career-affiliated institution" do
      allow(CanvasCareer::ExperienceResolver).to receive(:career_affiliated_institution?).with(root_account).and_return(false)
      post_course_completed
      expect(fake_producer.produced).to be_empty
    end

    it "no-ops when the horizon_autopilot feature flag is disabled" do
      root_account.disable_feature!(:horizon_autopilot)
      post_course_completed
      expect(fake_producer.produced).to be_empty
    end

    it "no-ops when the enable_kafka_events killswitch is disabled" do
      Account.site_admin.disable_feature!(:enable_kafka_events)
      post_course_completed
      expect(fake_producer.produced).to be_empty
    end

    it "no-ops when no root_account is passed" do
      described_class.post_event(
        Canvas::KafkaEvents::Events::COURSE_COMPLETED,
        root_account: nil,
        user:,
        payload: { course_id: course.global_id.to_s }
      )
      expect(fake_producer.produced).to be_empty
    end

    it "swallows producer errors and reports to statsd" do
      allow(fake_producer).to receive(:produce).and_raise(StandardError, "kafka is down")
      expect(Rails.logger).to receive(:error).with(/course_completed.*kafka is down/)
      allow(InstStatsd::Statsd).to receive(:distributed_increment)
      expect(InstStatsd::Statsd).to receive(:distributed_increment).with(
        "kafka_events.emit_errors",
        tags: { event: "course_completed" }
      )

      expect { post_course_completed }.not_to raise_error
    end
  end

  describe ".build_producer" do
    let(:fake_settings) { double }

    around do |example|
      prev = Canvas::KafkaEvents.producer
      Canvas::KafkaEvents.producer = nil
      example.run
    ensure
      Canvas::KafkaEvents.producer = prev
    end

    before do
      allow(DynamicSettings).to receive(:find).and_call_original
      allow(DynamicSettings).to receive(:find).with(tree: :private).and_return(fake_settings)
      allow(fake_settings).to receive(:[]).and_return(nil)
      allow(Rails.application.credentials).to receive(:kafka_events).and_return(nil)
    end

    def stub_credentials_kafka(**connection)
      allow(Rails.application.credentials).to receive(:kafka_events).and_return(connection.with_indifferent_access)
    end

    def stub_consul_kafka(**config)
      allow(fake_settings).to receive(:[]).with("kafka_events.yml", anything).and_return(YAML.dump(config.transform_keys(&:to_s)))
    end

    it "leaves producer nil when credentials have no kafka_events entry" do
      expect { described_class.build_producer }.not_to raise_error
      expect(Canvas::KafkaEvents.producer).to be_nil
    end

    it "leaves producer nil when brokers is blank even if topics are configured in Consul" do
      stub_consul_kafka(topics: { "course_events" => "course.events" })
      expect { described_class.build_producer }.not_to raise_error
      expect(Canvas::KafkaEvents.producer).to be_nil
    end

    it "raises when SASL is half-configured so boot fails fast" do
      stub_consul_kafka(topics: { "course_events" => "course.events" })
      stub_credentials_kafka(brokers: "b-1.example.com:9094", sasl_username: "canvas-producer")

      expect { described_class.build_producer }.to raise_error(
        Canvas::KafkaEvents::Config::ConfigError,
        /requires both sasl_username and sasl_password/
      )
      expect(Canvas::KafkaEvents.producer).to be_nil
    end

    it "raises when required topics are missing so boot fails fast" do
      stub_credentials_kafka(brokers: "b-1.example.com:9094", security_protocol: "PLAINTEXT")

      expect { described_class.build_producer }.to raise_error(
        Canvas::KafkaEvents::Config::ConfigError,
        /required topic\(s\) missing from DynamicSettings: course_events/
      )
      expect(Canvas::KafkaEvents.producer).to be_nil
    end

    it "builds a producer when fully configured" do
      stub_consul_kafka(topics: { "course_events" => "course.events" })
      stub_credentials_kafka(brokers: "b-1.example.com:9094", security_protocol: "PLAINTEXT")

      wd = instance_double(WaterDrop::Producer)
      monitor = instance_double(WaterDrop::Instrumentation::Monitor)
      allow(wd).to receive(:monitor).and_return(monitor)
      allow(monitor).to receive(:subscribe)
      allow(WaterDrop::Producer).to receive(:new).and_return(wd)

      described_class.build_producer

      expect(Canvas::KafkaEvents.producer).to be_a(Canvas::KafkaEvents::Producer)
    end

    it "logs and increments init_errors when Producer.new raises an unexpected error" do
      stub_consul_kafka(topics: { "course_events" => "course.events" })
      stub_credentials_kafka(brokers: "b-1.example.com:9094", security_protocol: "PLAINTEXT")
      allow(Canvas::KafkaEvents::Producer).to receive(:new).and_raise(StandardError, "waterdrop exploded")

      expect(Rails.logger).to receive(:error).with(/Kafka producer init error: waterdrop exploded/)
      allow(InstStatsd::Statsd).to receive(:distributed_increment)
      expect(InstStatsd::Statsd).to receive(:distributed_increment).with("kafka_events.init_errors")

      expect { described_class.build_producer }.not_to raise_error
      expect(Canvas::KafkaEvents.producer).to be_nil
    end
  end

  describe ".enabled_for?" do
    before do
      enable_all_gates
    end

    it "returns false when root_account is nil" do
      expect(described_class.enabled_for?(nil)).to be(false)
    end

    it "returns true when all gates are on" do
      expect(described_class.enabled_for?(root_account)).to be(true)
    end

    it "returns false when root_account is not career-affiliated even if other flags on" do
      allow(CanvasCareer::ExperienceResolver).to receive(:career_affiliated_institution?).with(root_account).and_return(false)
      expect(described_class.enabled_for?(root_account)).to be(false)
    end
  end
end
