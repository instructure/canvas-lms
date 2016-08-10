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
    notification_failure_queue.poll(config.slice(*POLL_PARAMS)) do |failure_summary_json|
      summary = parse_failure_summary(failure_summary_json)
      process_failure_summary(summary) if summary
    end
  end

  private

  def parse_failure_summary(summary)
    JSON.parse(summary.body)
  rescue JSON::ParserError
    nil
  end

  def process_failure_summary(summary)
    global_id = summary['global_id']
    error_message = summary['error']
    is_disabled_endpoint = error_message.include? "EndpointDisabled"
    error_context = summary['error_context']

    if Message.where(id: global_id).exists?
      message = Message.find(global_id)

      message.set_transmission_error
      message.transmission_errors = error_message if error_message
      message.save!

      # clean up disabled push endpoints
      if is_disabled_endpoint
        bad_endpoint_arn = error_context
        message.user.notification_endpoints.where(arn: bad_endpoint_arn).destroy_all
      end
    end
  end

  def notification_failure_queue
    return @notification_failure_queue if defined?(@notification_failure_queue)
    sqs = AWS::SQS.new(config)
    @notification_failure_queue = sqs.queues.named(config[:notification_failure_queue_name])
  end
end
