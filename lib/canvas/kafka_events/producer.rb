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

module Canvas::KafkaEvents
  class Producer
    def initialize(config)
      @config = config
      @config.validate!
      @producer = build_waterdrop
      log_ready
    end

    def produce(topic_key:, key:, payload:)
      topic = @config.topic_for(topic_key)
      return unless topic

      @producer.produce_async(topic:, key:, payload: payload.to_json)
    rescue WaterDrop::Errors::ProduceError, WaterDrop::Errors::ProducerClosedError => e
      Rails.logger.error("Kafka produce error on topic #{topic}: #{e.message}")
      InstStatsd::Statsd.distributed_increment("kafka_events.produce_errors")
      nil
    end

    def close
      @producer&.close
    rescue => e
      Rails.logger.warn("Kafka producer close error: #{e.message}")
    end

    private

    def build_waterdrop
      wd = WaterDrop::Producer.new do |c|
        c.kafka = @config.kafka_options
        c.logger = Rails.logger
      end
      wd.monitor.subscribe("error.occurred") do |event|
        InstStatsd::Statsd.distributed_increment("kafka_events.delivery_errors")
        Rails.logger.warn("Kafka delivery failed: #{event[:error]&.message}")
      end
      wd.monitor.subscribe("message.purged") do |event|
        # Fires when a buffered message hits message.timeout.ms without broker ack —
        # the event is silently dropped on the floor. Worth an alert.
        InstStatsd::Statsd.distributed_increment("kafka_events.messages_purged")
        Rails.logger.warn("Kafka message purged: #{event[:error]&.message}")
      end
      wd
    end

    def log_ready
      resolved = Events.topic_keys.map { |key| "#{key}=#{@config.topic_for(key)}" }.join(" ")
      Rails.logger.info("Kafka events producer ready: brokers=#{@config.brokers} #{resolved}")
    end
  end
end
