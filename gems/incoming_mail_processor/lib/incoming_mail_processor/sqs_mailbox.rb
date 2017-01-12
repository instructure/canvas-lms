#
# Copyright (C) 2015 Instructure, Inc.
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

require 'aws-sdk-v1'
require File.expand_path('../configurable_timeout', __FILE__)

module IncomingMailProcessor
  class SqsMailbox
    include ConfigurableTimeout

    attr_reader :config

    POLL_PARAMS = %i{initial_timeout idle_timeout wait_time_seconds visibility_timeout}.freeze

    def initialize(opts={})
      @config = opts
      wrap_with_timeout(self, [:connect, :move_message])
    end

    def connect
      @sqs = AWS::SQS.new(access_key_id: config[:access_key_id], secret_access_key: config[:secret_access_key])
      @incoming_mail_queue = @sqs.queues.named(config[:incoming_mail_queue_name])
    end

    def disconnect
    end

    def each_message(opts={})
      # stride and offset opts are ignored. queues safely handle simultaneous readers inherently
      @incoming_mail_queue.poll(config.slice(*POLL_PARAMS)) do |msg|
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
      target_queue = @sqs.queues.named(target_folder)
      target_queue.send_message(message_id.body) if target_queue
    end

    def unprocessed_message_count
      connect
      @incoming_mail_queue.approximate_number_of_messages
    end

    private

    def raw_contents(msg)
      sqs_body = JSON.parse(msg.body)
      sns_body = JSON.parse(sqs_body['Message'])
      key = sns_body['mail']['messageId']
      s3 = AWS::S3.new(access_key_id: config[:access_key_id], secret_access_key: config[:secret_access_key])
      obj = s3.buckets[config[:incoming_mail_bucket]].objects[key]
      obj.read
    end
  end
end
