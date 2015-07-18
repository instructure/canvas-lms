#
# Copyright (C) 2014 Instructure, Inc.
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

class BounceNotificationProcessor
  attr_reader :config

  POLL_PARAMS = %w{initial_timeout idle_timeout wait_time_seconds visibility_timeout}.map(&:to_sym)
  DEFAULT_CONFIG = {
    bounce_queue_name: 'canvas_notifications_bounces',
    idle_timeout: 10
  }

  def self.config
    @@config ||= ConfigFile.load('bounce_notifications').try(:symbolize_keys)
  end

  def self.enabled?
    !!config
  end

  def self.process(config = self.config)
    self.new(config).process
  end

  def initialize(config = self.class.config)
    @config = DEFAULT_CONFIG.merge(config)
  end

  def process
    bounce_queue.poll(config.slice(*POLL_PARAMS)) do |message|
      bounce_notification = parse_message(message)
      process_bounce_notification(bounce_notification) if bounce_notification
    end
  end

  private

  def bounce_queue
    return @bounce_queue if defined?(@bounce_queue)
    sqs = AWS::SQS.new(access_key_id: config[:access_key_id], secret_access_key: config[:secret_access_key])
    @bounce_queue = sqs.queues.named(config[:bounce_queue_name])
  end

  def parse_message(message)
    sqs_body = JSON.parse(message.body)
    sns_body = JSON.parse(sqs_body['Message'])
    bounce_notification = sns_body['bounce']
  end

  def process_bounce_notification(bounce_notification)
    return unless is_permanent_bounce?(bounce_notification)

    bouncy_addresses(bounce_notification).each do |address|
      CommunicationChannel.bounce_for_path(
        path: address,
        timestamp: bounce_timestamp(bounce_notification),
        details: bounce_notification,
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
