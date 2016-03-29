#
# Copyright (C) 2016 Instructure, Inc.
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

require 'aws-sdk'

class ConfigurationMissingError < StandardError; end

class NotificationFailureProcessor
  attr_reader :config

  POLL_PARAMS = %i(initial_timeout idle_timeout wait_time_seconds visibility_timeout).freeze
  DEFAULT_CONFIG = {
    notification_failure_queue_name: 'notification-service-failures',
    idle_timeout: 10
  }.freeze

  def self.config
    return @config if instance_variable_defined?(:@config)
    @config = ConfigFile.load('notification_failures').try(:symbolize_keys)
  end

  class << self
    alias_method :enabled?, :config
  end

  def self.process(config = self.config)
    new(config).process
  end

  def initialize(config = self.class.config)
    raise ConfigurationMissingError unless self.class.enabled? || config
    @config = DEFAULT_CONFIG.merge(config)
  end

  def process
    notification_failure_queue.poll(config.slice(*POLL_PARAMS)) do |message|
      failure_notification = parse_failure_notification(message)
      process_failure_notification(failure_notification) if failure_notification
    end
  end

  private

  def parse_failure_notification(message)
    JSON.parse(message.body)
  rescue JSON::ParserError
    nil
  end

  def process_failure_notification(notification)
    global_id = notification['global_id']
    error_message = notification['error']
    message = global_message(global_id)

    message.set_transmission_error if message
    message.transmission_errors = error_message if message && error_message
    message.save!
  end

  def notification_failure_queue
    return @notification_failure_queue if defined?(@notification_failure_queue)
    sqs = AWS::SQS.new(config)
    @notification_failure_queue = sqs.queues.named(config[:notification_failure_queue_name])
  end

  def global_message(global_id)
    Message.find(global_id)
  end
end