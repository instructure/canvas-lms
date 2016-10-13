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

require 'spec_helper'

describe IncomingMailProcessor::SqsMailbox do
  include_examples 'Mailbox'

  let(:default_config) do
    {
      access_key_id: 'access-key',
      secret_access_key: 'secret-access-key',
      incoming_mail_queue_name: 'incoming-mail-queue',
      error_folder: 'error-mail-queue',
      idle_timeout: 1,
      incoming_mail_bucket: 'bucket',
      region: 'us-east-1'
    }
  end

  let(:queue) { double }
  let(:sqs_message_body) {
    {
      mail: {
        messageId: 's3_key'
      }
    }.to_json
  }
  let(:sqs_message) { double(body: sqs_message_body) }
  let(:message_bucket) { double(object: double(get: double(body: StringIO.new("raw email")))) }

  subject {IncomingMailProcessor::SqsMailbox.new(default_config)}

  describe '#connect' do
    it 'returns the incoming mail queue' do
      expect_any_instance_of(Aws::SQS::Client).to receive(:get_queue_url).and_return(double(queue_url: 'some_url'))
      expect(subject.connect).to be_a Aws::SQS::QueuePoller
    end
  end

  describe '#each_message' do
    it 'yields the SQS message and raw message content from S3' do
      s3 = double()
      expect(s3).to receive(:bucket).
          with(default_config[:incoming_mail_bucket]).
          and_return(message_bucket)
      expect(Aws::S3::Resource).to receive(:new).and_return(s3)
      sqs = double()
      expect(sqs).to receive(:get_queue_url).
          with(queue_name: default_config[:incoming_mail_queue_name]).
          and_return(double(queue_url: 'some_url'))
      expect(Aws::SQS::Client).to receive(:new).and_return(sqs)
      expect(Aws::SQS::QueuePoller).to receive(:new).and_return(queue)
      expect(queue).to receive(:poll).and_yield(sqs_message)
      subject.connect
      subject.each_message do |msg, contents|
        expect(msg).to eq sqs_message
        expect(contents).to eq 'raw email'
      end
    end
  end

  describe '#move_message' do
    it 're-enqueues messages in the given queue' do
      msg = double
      expect(msg).to receive(:body).and_return('msg body')

      sqs = double()
      expect(Aws::SQS::Client).to receive(:new).and_return(sqs)
      expect(sqs).to receive(:get_queue_url).
          with(queue_name: default_config[:incoming_mail_queue_name]).
          and_return(double(queue_url: 'incoming_url'))
      expect(sqs).to receive(:get_queue_url).
          with(queue_name: default_config[:error_folder]).
          and_return(double(queue_url: 'error_url'))
      expect(sqs).to receive(:send_message).
          with(message_body: 'msg body', queue_url: 'error_url')
      subject.connect
      subject.move_message(msg, default_config[:error_folder])
    end
  end

  describe '#unprocessed_message_count' do
    it 'fetches the number of visible messages from the queue' do
      sqs = double()
      expect(Aws::SQS::Client).to receive(:new).and_return(sqs)
      expect(sqs).to receive(:get_queue_url).
          with(queue_name: default_config[:incoming_mail_queue_name]).
          and_return(double(queue_url: 'my_url'))
      response = double(attributes: { 'ApproximateNumberOfMessages' => '5' })
      expect(sqs).to receive(:get_queue_attributes).
          with(queue_url: 'my_url', attribute_names: [ 'ApproximateNumberOfMessages'] ).
          and_return(response)
      expect(subject.unprocessed_message_count).to eq 5
    end
  end
end
