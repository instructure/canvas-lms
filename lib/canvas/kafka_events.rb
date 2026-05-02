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
  Event = Struct.new(:name, :event_type, :topic_key)

  module Events
    COURSE_COMPLETED = Event.new(
      name: "course_completed",
      event_type: "canvas.course.completed",
      topic_key: "course_events"
    ).freeze

    def self.topic_keys
      constants.map { |c| const_get(c) }.grep(Event).map(&:topic_key).uniq
    end
  end

  class << self
    attr_accessor :producer
  end

  def self.build_producer
    config = Config.new
    return unless config.brokers_configured?

    require "waterdrop"
    @producer = Producer.new(config)
  rescue Config::ConfigError
    raise
  rescue => e
    Rails.logger.error("Kafka producer init error: #{e.message}")
    InstStatsd::Statsd.distributed_increment("kafka_events.init_errors")
    nil
  end

  def self.post_event(event, root_account:, user:, payload:, occurred_at: nil)
    return unless event.is_a?(Event)
    return unless enabled_for?(root_account)

    envelope = build_envelope(event.event_type, root_account, user, payload, occurred_at)
    producer&.produce(topic_key: event.topic_key, key: root_account.uuid, payload: envelope)
  rescue => e
    Rails.logger.error("Canvas::KafkaEvents.post_event failed for #{event.name}: #{e.message}")
    InstStatsd::Statsd.distributed_increment(
      "kafka_events.emit_errors",
      tags: { event: event.name }
    )
    nil
  end

  def self.enabled_for?(root_account)
    return false unless root_account

    CanvasCareer::ExperienceResolver.career_affiliated_institution?(root_account) &&
      root_account.feature_enabled?(:horizon_autopilot) &&
      Account.site_admin.feature_enabled?(:enable_kafka_events)
  end

  def self.build_envelope(event_type, root_account, user, payload, occurred_at)
    timestamp = (occurred_at || Time.now.utc).utc.iso8601(3)
    (payload || {}).merge(
      event_id: SecureRandom.uuid,
      event_type:,
      root_account_uuid: root_account.uuid,
      timestamp:,
      user_uuid: user.uuid
    )
  end
end
