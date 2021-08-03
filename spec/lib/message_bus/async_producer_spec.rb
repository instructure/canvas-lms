# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

describe MessageBus::AsyncProducer do

  before(:each) do
    skip("pulsar config required to test") unless MessageBus.enabled?
  end

  describe "#produce_message error handling" do
    it "re-raises errors correctly if they're not rescuable" do
      Bundler.require(:pulsar)
      producer = ::MessageBus::AsyncProducer.new(start_thread: false)
      allow(MessageBus).to receive(:producer_for).and_raise(::Pulsar::Error::AlreadyClosed)
      expect{ producer.send(:produce_message, ['a', 'b', 'c']) }.to raise_error(::Pulsar::Error::AlreadyClosed)
    end
  end

  describe "push" do

    around(:each) do |example|
      old_interval = MessageBus.worker_process_interval_lambda
      old_queue_size = MessageBus.max_mem_queue_size_lambda
      old_logger = MessageBus.logger
      # let's not waste time with queue throttling in tests
      MessageBus.worker_process_interval = -> { 0.01 }
      MessageBus.max_mem_queue_size = -> { 10 }
      MessageBus.logger = Rails.logger
      example.run
    ensure
      MessageBus.worker_process_interval = old_interval unless old_interval.nil?
      MessageBus.max_mem_queue_size_lambda = old_queue_size unless old_queue_size.nil?
      MessageBus.logger = old_logger
    end

    after(:each) do
      MessageBus.reset!
    end

    let(:producer){ MessageBus::AsyncProducer.new(start_thread: false) }
    let(:namespace){ "test-only" }

    it "pushes onto the queue but does not execute" do
      topic_name = "lazily-created-topic-#{SecureRandom.hex(16)}"
      subscription_name = "subscription-#{SecureRandom.hex(4)}"
      log_values = {test_key: "test_val"}
      log_values_2 = {test_key_2: "test_val_2"}
      producer.push(namespace, topic_name, log_values.to_json)
      producer.push(namespace, topic_name, log_values_2.to_json)
      expect(producer.queue_depth).to eq(2)

      consumer = MessageBus.consumer_for(namespace, topic_name, subscription_name)
      # if we get no error here we had a problem
      # because the producer should only have queued
      # stuff and not sent it.
      expect{ consumer.receive(100) }.to raise_error(Pulsar::Error::Timeout)

      producer.start!
      producer.stop!

      expect(producer.queue_depth).to eq(0)
      messages = []
      2.times{ messages << consumer.receive(100) }
      # we got the 2 messages pushed, topic should be empty
      expect{ consumer.receive(100) }.to raise_error(Pulsar::Error::Timeout)
      expect(JSON.parse(messages[0].data)["test_key"]).to eq("test_val")
      expect(JSON.parse(messages[1].data)["test_key_2"]).to eq("test_val_2")
    end

    it "rejects items when queue is full" do
      topic_name = "lazily-created-topic-#{SecureRandom.hex(16)}"
      log_values = {test_key: "test_val"}
      msg = log_values.to_json
      MessageBus.max_mem_queue_size = -> { 5 }
      5.times { expect{ producer.push(namespace, topic_name, msg) }.to_not raise_error }
      expect{ producer.push(namespace, topic_name, msg) }.to raise_error(::MessageBus::MemoryQueueFullError)
    end
  end
end
