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

class VerySpecialAsycnMbTestError < StandardError
end

describe MessageBus::AsyncProducer do
  let(:namespace) { "test-only" }

  before(:each) do
    skip("pulsar config required to test") unless MessageBus.enabled?
  end

  describe "#produce_message error handling" do
    specs_require_sharding

    before(:once) do
      Bundler.require(:pulsar)
      ErrorReport.delete_all
    end

    it "re-raises errors correctly if they're not rescuable" do
      producer = ::MessageBus::AsyncProducer.new(start_thread: false)
      allow(MessageBus).to receive(:producer_for).and_raise(::Pulsar::Error::AlreadyClosed)
      expect { producer.send(:produce_message, 'a', 'b', 'c') }.to raise_error(::Pulsar::Error::AlreadyClosed)
    end

    it "sends error reports to contextual shard" do
      @shard1.activate do
        prior_err_count = ErrorReport.count
        prior_err2_count = @shard2.activate { ErrorReport.count }
        producer = ::MessageBus::AsyncProducer.new(start_thread: false)
        @shard2.activate { producer.push('a', 'b', 'c') } # will write shard2 as shard id
        allow(producer).to receive(:produce_message).and_raise(VerySpecialAsycnMbTestError)
        expect(producer.queue_depth).to eq(1)
        expect { producer.send(:process_one_queue_item) }.to_not raise_error
        expect(ErrorReport.count).to eq(prior_err_count)
        @shard2.activate do
          expect(ErrorReport.count).to eq(prior_err2_count + 1)
        end
      end
    end
  end

  describe "push" do
    around(:each) do |example|
      # let's not waste time with queue throttling in tests
      MessageBus.worker_process_interval = -> { 0.01 }
      MessageBus.max_mem_queue_size = -> { 10 }
      MessageBus.logger = Rails.logger
      example.run
    ensure
      Canvas::MessageBusConfig.apply # resets config changes made to interval and queue size
    end

    after(:each) do
      MessageBus.reset!
    end

    let(:producer) { MessageBus::AsyncProducer.new(start_thread: false) }

    it "pushes onto the queue but does not execute" do
      topic_name = "lazily-created-topic-#{SecureRandom.hex(16)}"
      subscription_name = "subscription-#{SecureRandom.hex(4)}"
      log_values = { test_key: "test_val" }
      log_values_2 = { test_key_2: "test_val_2" }
      producer.push(namespace, topic_name, log_values.to_json)
      producer.push(namespace, topic_name, log_values_2.to_json)
      expect(producer.queue_depth).to eq(2)

      consumer = MessageBus.consumer_for(namespace, topic_name, subscription_name)
      # if we get no error here we had a problem
      # because the producer should only have queued
      # stuff and not sent it.
      expect { consumer.receive(100) }.to raise_error(Pulsar::Error::Timeout)

      producer.start!
      producer.stop!

      expect(producer.queue_depth).to eq(0)
      messages = []
      2.times { messages << consumer.receive(100) }
      # we got the 2 messages pushed, topic should be empty
      expect { consumer.receive(100) }.to raise_error(Pulsar::Error::Timeout)
      expect(JSON.parse(messages[0].data)["test_key"]).to eq("test_val")
      expect(JSON.parse(messages[1].data)["test_key_2"]).to eq("test_val_2")
    end

    it "rejects items when queue is full" do
      topic_name = "lazily-created-topic-#{SecureRandom.hex(16)}"
      log_values = { test_key: "test_val" }
      msg = log_values.to_json
      MessageBus.max_mem_queue_size = -> { 5 }
      5.times { expect { producer.push(namespace, topic_name, msg) }.to_not raise_error }
      expect { producer.push(namespace, topic_name, msg) }.to raise_error(::MessageBus::MemoryQueueFullError)
    end
  end

  describe "running thread" do
    specs_require_sharding

    before(:all) do
      Bundler.require(:pulsar)
    end

    around(:each) do |example|
      # let's not waste time with queue throttling in tests
      MessageBus.worker_process_interval = -> { 0.01 }
      example.run
    ensure
      Canvas::MessageBusConfig.apply # resets config changes made to interval and queue size
    end

    it "releases db connections appropriately" do
      producer = ::MessageBus::AsyncProducer.new(start_thread: false)
      # no residual connections should be in this thread at all
      # we want to go from a clean slate every time
      ActiveRecord::Base.connection_pool.current_pool.lock_thread = false
      @shard2.activate do
        producer.push(namespace, 'some-topic-12345', { key: "msg1" }.to_json)
        producer.push(namespace, 'some-topic-12345', { key: "msg2" }.to_json)
        producer.push(namespace, 'some-topic-12345', { key: "msg3" }.to_json)
      end
      # at this point the producer has some messages in it's queue but
      # has not done anything to spark a connection.
      #
      Shard.clear_cache # force thread to pull a connection to default shard
      producer.start!
      # Now kick it off, and for each message it will have to perform
      # a shard lookup so it should lease a connection on the default shard.
      # quick sleep to give the thread a chance to pre-empt.
      sleep(0.01) # rubocop:disable Lint/NoSleep

      # clear idle connections to force switchman to do it's thing and
      # simulate one of these events happening organically
      ActiveRecord::Base.connection_pool.clear_idle_connections!(Time.zone.now - 60)
      #
      # at this point the thread will have a leased connection to
      # the default shard and it should NOT have gone back to the queue,
      # so we should be able to pull a connection in this thread.
      expect do
        conn = ActiveRecord::Base.connection_pool.current_pool.checkout
        ActiveRecord::Base.connection_pool.current_pool.checkin(conn)
      end.to_not raise_error
      producer.stop!
    end
  end
end
