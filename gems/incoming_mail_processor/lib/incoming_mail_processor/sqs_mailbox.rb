#
# Copyright (C) 2015 - present Instructure, Inc.
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

require 'aws-sdk-s3'
require 'aws-sdk-sqs'
require_relative 'configurable_timeout'

module IncomingMailProcessor
  class SqsMailbox
    include ConfigurableTimeout

    attr_reader :config

    POLL_PARAMS = %i{idle_timeout wait_time_seconds visibility_timeout}.freeze

    def initialize(opts={})
      @config = opts
      wrap_with_timeout(self, [:connect, :move_message])
    end

    def connect
      @sqs = Aws::SQS::Client.new(config.slice(:access_key_id,
                                               :secret_access_key,
                                               :endpoint,
                                               :region))
      @queue_url = @sqs.get_queue_url(queue_name: config[:incoming_mail_queue_name]).queue_url
      @incoming_mail_queue = Aws::SQS::QueuePoller.new(@queue_url, client: @sqs)
    end

    def disconnect
    end

    def each_message(opts={})
      start_time = Time.now
      iteration_high_water = config[:iteration_high_water] || 300
      @incoming_mail_queue.before_request do |_stats|
        throw :stop_polling if Time.now - start_time > iteration_high_water
      end

      poll_params = config.slice(*POLL_PARAMS)
      poll_params[:idle_timeout] ||= 10

      # stride and offset opts are ignored. queues safely handle simultaneous readers inherently
      @incoming_mail_queue.poll(poll_params) do |msg|
        # We don't really have a message id. The message object is how we refer to a message, so return that
        yield msg, raw_contents(msg)
      end # Messages are deleted as the block exits normally
    end

    def delete_message(message_id)
      # Messages are automatically deleted during #each_message polling
      # do we need to delete the s3 object?
    end

    def move_message(message_id, target_folder)
      # This is less moving and more re-enqueuing in another queue
      target_queue_url = @sqs.get_queue_url(queue_name: target_folder)
      if target_queue_url
        @sqs.send_message(message_body: message_id.body, queue_url: target_queue_url.queue_url)
      end
    end

    def unprocessed_message_count
      connect
      @sqs.get_queue_attributes(attribute_names: ["ApproximateNumberOfMessages"],
                                queue_url: @queue_url).
          attributes["ApproximateNumberOfMessages"].to_i
    end

    private

    def raw_contents(msg)
      sqs_body = JSON.parse(msg.body)
      sns_body = JSON.parse(sqs_body['Message'])
      key = sns_body['mail']['messageId']
      s3 = Aws::S3::Resource.new(access_key_id: config[:access_key_id], secret_access_key: config[:secret_access_key],
        region: config[:region] || 'us-east-1')
      obj = s3.bucket(config[:incoming_mail_bucket]).object(key)
      obj.get.body.read
    end
  end
end
