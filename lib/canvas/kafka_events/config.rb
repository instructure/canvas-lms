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
  class Config
    class ConfigError < StandardError; end

    def initialize
      @operational_config = load_operational_config
      @connection_config = load_connection_config
    end

    def brokers_configured?
      brokers.present?
    end

    def sasl_configured?
      sasl_username.present? || security_protocol.to_s.start_with?("SASL")
    end

    def sasl_credentials_complete?
      sasl_username.present? && sasl_password.present?
    end

    def brokers = @connection_config[:brokers]
    def security_protocol = @connection_config[:security_protocol] || "SASL_SSL"
    def sasl_mechanism = @connection_config[:sasl_mechanism] || "PLAIN"
    def sasl_username = @connection_config[:sasl_username]
    def sasl_password = @connection_config[:sasl_password]
    def client_id = @operational_config["client_id"] || "canvas"
    def message_timeout_ms = @operational_config["message_timeout_ms"] || 300_000
    def queue_buffering_max_messages = @operational_config["queue_buffering_max_messages"] || 100_000
    def reconnect_backoff_ms = @operational_config["reconnect_backoff_ms"] || 100
    def reconnect_backoff_max_ms = @operational_config["reconnect_backoff_max_ms"] || 10_000

    def topic_for(key)
      (@operational_config["topics"] || {})[key.to_s]
    end

    def kafka_options
      {
        "bootstrap.servers": brokers,
        "security.protocol": security_protocol,
        "sasl.mechanisms": sasl_mechanism,
        "sasl.username": sasl_username,
        "sasl.password": sasl_password,
        "client.id": client_id,
        acks: "all",
        "enable.idempotence": "true",
        "compression.type": "zstd",
        "socket.keepalive.enable": "true",
        "linger.ms": "50",
        "message.timeout.ms": message_timeout_ms.to_s,
        "queue.buffering.max.messages": queue_buffering_max_messages.to_s,
        "reconnect.backoff.ms": reconnect_backoff_ms.to_s,
        "reconnect.backoff.max.ms": reconnect_backoff_max_ms.to_s,
      }.compact
    end

    def validate!
      if sasl_configured? && !sasl_credentials_complete?
        raise ConfigError,
              "kafka_events connection requires both sasl_username and sasl_password when SASL is in use"
      end

      missing = Events.topic_keys.reject { |key| topic_for(key).present? }
      return if missing.empty?

      raise ConfigError,
            "kafka_events has brokers configured but required topic(s) missing from DynamicSettings: #{missing.join(", ")}"
    end

    private

    def load_operational_config
      parsed = YAML.safe_load(DynamicSettings.find(tree: :private)["kafka_events.yml", failsafe: nil] || "{}")
      parsed.is_a?(Hash) ? parsed : {}
    rescue => e
      Rails.logger.warn("Kafka operational settings load error: #{e.message}")
      {}
    end

    def load_connection_config
      Rails.application.credentials.kafka_events&.with_indifferent_access || {}
    end
  end
end
