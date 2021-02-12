# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require 'aws-sdk-sqs'

class BounceNotificationProcessor
  attr_reader :config

  POLL_PARAMS = %i{idle_timeout wait_time_seconds visibility_timeout}.freeze
  DEFAULT_CONFIG = {
    bounce_queue_name: 'canvas_notifications_bounces',
    idle_timeout: 10
  }.freeze

  def self.config
    ConfigFile.load('bounce_notifications').try(:symbolize_keys).try(:freeze)
  end

  def self.enabled?
    !!self.config
  end

  def self.process
    bounce = self.new
    key = 'bounce_processors_for_region_' + bounce.config[:region].to_s
    num_of_jobs = Setting.get(key, '0').to_i
    num_of_jobs.times { self.new.delay(priority: Delayed::LOW_PRIORITY).process }
    bounce.process
  end

  def initialize
    @config = DEFAULT_CONFIG.merge(self.class.config || {})
  end

  def process
    return nil unless self.class.enabled?
    start = Time.now.utc

    bounce_queue.poll(config.slice(*POLL_PARAMS)) do |message|
      bounce_notification = parse_message(message)
      if bounce_notification
        process_bounce_notification(bounce_notification)
      else
        InstStatsd::Statsd.increment('bounce_notification_processor.processed.no_bounce')
      end

      # this job gets scheduled every 5 minutes and then can queue additional
      # jobs; in order to release db resources and allow jobs to restart
      # gracefully, don't run longer than 5 minutes for any particular instance.
      break if Time.now.utc - start >= 5.minutes.to_i
    end
  end

  private

  def bounce_queue
    return @bounce_queue if defined?(@bounce_queue)
    sqs = Aws::SQS::Client.new(config.slice(:access_key_id, :secret_access_key, :region, :endpoint))
    @bounce_queue = Aws::SQS::QueuePoller.new(sqs.get_queue_url(queue_name: config[:bounce_queue_name]).queue_url, client: sqs)
  end

  def parse_message(message)
    sqs_body = JSON.parse(message.body)
    sns_body = JSON.parse(sqs_body['Message'])
    sns_body['bounce']
  end

  def process_bounce_notification(bounce_notification)
    type = if is_suppression_bounce?(bounce_notification)
      'suppression'
    elsif is_permanent_bounce?(bounce_notification)
      'permanent'
    else
      'transient'
    end
    InstStatsd::Statsd.increment("bounce_notification_processor.processed.#{type}")

    bouncy_addresses(bounce_notification).each do |address|
      CommunicationChannel.bounce_for_path(
        path: address,
        timestamp: bounce_timestamp(bounce_notification),
        details: bounce_notification,
        permanent_bounce: is_permanent_bounce?(bounce_notification),
        suppression_bounce: is_suppression_bounce?(bounce_notification)
      )
    end
  end

  def is_permanent_bounce?(bounce)
    bounce['bounceType'] == 'Permanent'
  end

  def is_suppression_bounce?(bounce)
    bounce['bounceSubType'] == 'Suppressed'
  end

  def bounce_timestamp(bounce)
    bounce['timestamp']
  end

  def bouncy_addresses(bounce)
    bounce['bouncedRecipients'].map {|r| r['emailAddress'] }
  end
end
