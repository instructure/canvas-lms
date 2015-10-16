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
    }
  end

  let(:queue_collection) {mock}
  let(:queue) {mock}
  let(:sqs_message_body) {
    {
      Message: {
        mail: {
          messageId: 's3_key'
        }
      }.to_json
    }
  }
  let(:sqs_message) {stub(body: sqs_message_body.to_json)} # yes, this is double json'd
  let(:message_bucket) {stub(objects:{'s3_key' => StringIO.new("raw email")})}

  subject {IncomingMailProcessor::SqsMailbox.new(default_config)}

  before(:all) do
    AWS.stub!
  end

  describe '#connect' do
    it 'returns the incoming mail queue' do
      expect(subject.connect).to be_a AWS::SQS::Queue
    end
  end

  describe '#each_message' do
    it 'yields the SQS message and raw message content from S3' do
      AWS::S3.any_instance.expects(:buckets).returns({default_config[:incoming_mail_bucket] => message_bucket})
      AWS::SQS.any_instance.expects(:queues).returns(queue_collection)
      queue_collection.expects(:named).with(default_config[:incoming_mail_queue_name]).returns(queue)
      queue.expects(:poll).yields(sqs_message)
      subject.connect
      subject.each_message do |msg, contents|
        expect(msg).to eq sqs_message
        expect(contents).to eq 'raw email'
      end
    end
  end

  describe '#move_message' do
    it 're-enqueues messages in the given queue' do
      msg = mock
      msg.expects(:body).returns('msg body')
      AWS::SQS.any_instance.expects(:queues).twice.returns(queue_collection)
      queue_collection.expects(:named).with(default_config[:incoming_mail_queue_name]).returns(queue)
      queue_collection.expects(:named).with(default_config[:error_folder]).returns(queue)
      queue.expects(:send_message).with('msg body')
      subject.connect
      subject.move_message(msg, default_config[:error_folder])
    end
  end

  describe '#unprocessed_message_count' do
    it 'fetches the number of visible messages from the queue' do
      AWS::SQS.any_instance.expects(:queues).returns(queue_collection)
      queue_collection.expects(:named).with(default_config[:incoming_mail_queue_name]).returns(queue)
      queue.expects(:approximate_number_of_messages).returns(5)
      expect(subject.unprocessed_message_count).to eq 5
    end
  end
end
