# frozen_string_literal: true

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

require "spec_helper"

describe IncomingMailProcessor::SqsMailbox do
  subject { IncomingMailProcessor::SqsMailbox.new(default_config) }

  let(:s3_get_response) { instance_double(Aws::S3::Types::GetObjectOutput, body: StringIO.new("raw email")) }
  let(:s3_object) { instance_double(Aws::S3::Object, get: s3_get_response) }
  let(:message_bucket) { instance_double(Aws::S3::Bucket, object: s3_object) }
  let(:sqs_message) { instance_double(Aws::SQS::Types::Message, body: sqs_message_body) }
  let(:sqs_message_body) do
    {
      Message: {
        mail: {
          messageId: "s3_key"
        }
      }.to_json
    }.to_json
  end
  let(:queue) { instance_double(Aws::SQS::QueuePoller) }
  let(:default_config) do
    {
      incoming_mail_queue_name: "incoming-mail-queue",
      error_folder: "error-mail-queue",
      idle_timeout: 1,
      incoming_mail_bucket: "bucket",
      region: "us-east-1"
    }
  end

  it_behaves_like "Mailbox"

  describe "#connect" do
    it "returns the incoming mail queue" do
      expect_any_instance_of(Aws::SQS::Client).to receive(:get_queue_url).and_return(instance_double(Aws::SQS::Types::GetQueueUrlResult, queue_url: "some_url"))
      expect(subject.connect).to be_a Aws::SQS::QueuePoller
    end
  end

  describe "#each_message" do
    it "yields the SQS message and raw message content from S3" do
      s3 = instance_double(Aws::S3::Resource)
      expect(s3).to receive(:bucket)
        .with(default_config[:incoming_mail_bucket])
        .and_return(message_bucket)
      expect(Aws::S3::Resource).to receive(:new).and_return(s3)
      sqs = instance_double(Aws::SQS::Client)
      expect(sqs).to receive(:get_queue_url)
        .with(queue_name: default_config[:incoming_mail_queue_name])
        .and_return(instance_double(Aws::SQS::Types::GetQueueUrlResult, queue_url: "some_url"))
      expect(Aws::SQS::Client).to receive(:new).and_return(sqs)
      expect(Aws::SQS::QueuePoller).to receive(:new).and_return(queue)
      expect(queue).to receive(:before_request)
      expect(queue).to receive(:poll).and_yield(sqs_message)
      subject.connect
      subject.each_message do |msg, contents|
        expect(msg).to eq sqs_message
        expect(contents).to eq "raw email"
      end
    end
  end

  describe "#move_message" do
    it "re-enqueues messages in the given queue" do
      msg = instance_double(Aws::SQS::Types::Message)
      expect(msg).to receive(:body).and_return("msg body")

      sqs = instance_double(Aws::SQS::Client)
      expect(Aws::SQS::Client).to receive(:new).and_return(sqs)
      expect(sqs).to receive(:get_queue_url)
        .with(queue_name: default_config[:incoming_mail_queue_name])
        .and_return(instance_double(Aws::SQS::Types::GetQueueUrlResult, queue_url: "incoming_url"))
      expect(sqs).to receive(:get_queue_url)
        .with(queue_name: default_config[:error_folder])
        .and_return(instance_double(Aws::SQS::Types::GetQueueUrlResult, queue_url: "error_url"))
      expect(sqs).to receive(:send_message)
        .with(message_body: "msg body", queue_url: "error_url")
      subject.connect
      subject.move_message(msg, default_config[:error_folder])
    end
  end

  describe "#unprocessed_message_count" do
    it "fetches the number of visible messages from the queue" do
      sqs = instance_double(Aws::SQS::Client)
      expect(Aws::SQS::Client).to receive(:new).and_return(sqs)
      expect(sqs).to receive(:get_queue_url)
        .with(queue_name: default_config[:incoming_mail_queue_name])
        .and_return(instance_double(Aws::SQS::Types::GetQueueUrlResult, queue_url: "my_url"))
      response = instance_double(Aws::SQS::Types::GetQueueAttributesResult, attributes: { "ApproximateNumberOfMessages" => "5" })
      expect(sqs).to receive(:get_queue_attributes)
        .with(queue_url: "my_url", attribute_names: ["ApproximateNumberOfMessages"])
        .and_return(response)
      expect(subject.unprocessed_message_count).to eq 5
    end
  end
end
