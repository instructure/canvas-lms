# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

require "aws-sdk-sqs"

class ConfigurationMissingError < StandardError; end

class NotificationFailureProcessor
  attr_reader :config

  POLL_PARAMS = %i[idle_timeout wait_time_seconds visibility_timeout].freeze
  DEFAULT_CONFIG = {
    notification_failure_queue_name: "notification-service-failures",
    # stop the loop if no message received for 10s
    idle_timeout: 10,
    # stop the loop (and wait for it to process the job again) if we've been running
    # for this long
    iteration_high_water: 300
  }.freeze

  def self.config
    ConfigFile.load("notification_failures").try(:symbolize_keys).try(:freeze)
  end

  def self.enabled?
    !!config
  end

  def self.process
    new.process
  end

  def initialize
    @config = DEFAULT_CONFIG.merge(self.class.config || {})
  end

  def process
    return nil unless self.class.enabled?

    start_time = Time.now
    notification_failure_queue.before_request do |_stats|
      throw :stop_polling if Time.now - start_time > config[:iteration_high_water]
    end

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
    global_id = summary["global_id"]
    error_message = summary["error"]
    is_disabled_endpoint = error_message&.include? "EndpointDisabled"
    error_context = summary["error_context"]

    message_id, timestamp = Message.parse_notification_service_id(global_id)
    scope = Message.where(id: message_id)
    scope = scope.at_timestamp(timestamp) if timestamp
    message = scope.take
    if message
      message.set_transmission_error
      message.transmission_errors = error_message if error_message
      message.save_using_update_all

      # clean up disabled push endpoints
      if is_disabled_endpoint
        bad_endpoint_arn = error_context
        message.user.notification_endpoints.where(arn: bad_endpoint_arn).destroy_all
      end
    end
  end

  def notification_failure_queue
    return @notification_failure_queue if defined?(@notification_failure_queue)

    conf = Canvas::AWS.validate_v2_config(config, "notification_failures.yml").dup
    conf[:credentials] ||= Canvas::AwsCredentialProvider.new("notification_failures_creds", conf[:vault_credential_path])
    conf.except!(*POLL_PARAMS, :vault_credential_path)
    conf.delete(:iteration_high_water)
    conf.delete(:initial_timeout) # old, no longer supported poll param
    queue_name = conf.delete(:notification_failure_queue_name)
    sqs = Aws::SQS::Client.new(conf)
    queue_url = sqs.get_queue_url(queue_name:).queue_url
    @notification_failure_queue = Aws::SQS::QueuePoller.new(queue_url, client: sqs)
  end
end
