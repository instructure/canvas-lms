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

describe MessageBus do
  TEST_MB_NAMESPACE = "test-only"

  around(:each) do |example|
    old_interval = MessageBus.worker_process_interval_lambda
    # let's not waste time with queue throttling in tests
    MessageBus.worker_process_interval = -> { 0.01 }
    example.run
  ensure
    MessageBus.worker_process_interval = old_interval unless old_interval.nil?
  end

  before(:each) do
    skip("pulsar config required to test") unless MessageBus.enabled?
  end

  after(:each) do
    MessageBus.process_all_and_reset!
  end

  describe ".reset!" do
    it "still nils out the client, even if the client is closed already" do
      client = MessageBus.client
      allow(client).to receive(:close) do
        raise ::Pulsar::Error::AlreadyClosed
      end
      expect { MessageBus.reset! }.to_not raise_error
      new_client = MessageBus.client
      expect(new_client).to_not eq(client)
    end
  end

  it "can send messages and then later receive messages" do
    topic_name = "lazily-created-topic-#{SecureRandom.hex(16)}"
    subscription_name = "subscription-#{SecureRandom.hex(4)}"
    producer = MessageBus.producer_for(TEST_MB_NAMESPACE, topic_name)
    log_values = { test_key: "test_val" }
    producer.send(log_values.to_json)
    consumer = MessageBus.consumer_for(TEST_MB_NAMESPACE, topic_name, subscription_name)
    msg = consumer.receive(1000)
    consumer.acknowledge(msg)
    # normally you would process the message before acknowledging it
    # but we're trying to keep the external state as clean as possible in the tests.
    expect(JSON.parse(msg.data)['test_key']).to eq("test_val")
  end

  it "can send a single message resiliant to timeout" do
    topic_name = "lazily-created-topic-#{SecureRandom.hex(17)}"
    subscription_name = "subscription-#{SecureRandom.hex(5)}"
    call_count = 0
    original_producer_for = MessageBus.method(:producer_for)
    allow(MessageBus).to receive(:producer_for) do |namespace, topic_name|
      call_count += 1
      raise(::Pulsar::Error::Timeout, "Big Ops Fail") if call_count <= 1

      original_producer_for.call(namespace, topic_name)
    end
    MessageBus.send_one_message(TEST_MB_NAMESPACE, topic_name, { test_my_key: "test_my_val" }.to_json)
    MessageBus.production_worker.stop! # make sure we actually get through shipping the messages
    consumer = MessageBus.consumer_for(TEST_MB_NAMESPACE, topic_name, subscription_name)
    msg = consumer.receive(1000)
    consumer.acknowledge(msg)
    # normally you would process the message before acknowledging it
    # but we're trying to keep the external state as clean as possible in the tests.
    expect(JSON.parse(msg.data)['test_my_key']).to eq("test_my_val")
  end

  it "only parses the YAML one time as long as it doesn't change" do
    # make sure we aren't parsing every time
    expect(YAML).to receive(:safe_load).at_most(:twice).and_call_original
    original_config = nil
    5.times { original_config = MessageBus.config }
    # force the config to change, so we get a second yaml parse
    yaml = "NOT_THE_ORIGINAL: config"
    allow(DynamicSettings).to receive(:find).and_return({ 'pulsar.yml' => yaml })
    other_config = nil
    5.times { other_config = MessageBus.config }
    # make sure that the contents change when the dynamic settings change
    expect(other_config).to_not eq(original_config)
  end

  describe "connection caching" do
    it "caches a single producer connection until you force it" do
      topic_name = "cachable-created-topic-#{SecureRandom.hex(16)}"
      producer = MessageBus.producer_for(TEST_MB_NAMESPACE, topic_name)
      producer2 = MessageBus.producer_for(TEST_MB_NAMESPACE, topic_name)
      producer3 = MessageBus.producer_for(TEST_MB_NAMESPACE, topic_name)
      expect(producer.class).to eq(Pulsar::Producer)
      expect(producer3).to be(producer)
      expect(producer2).to be(producer)
      producer4 = MessageBus.producer_for(TEST_MB_NAMESPACE, topic_name, force_fresh: true)
      expect(producer4).to_not be(producer)
      producer5 = MessageBus.producer_for(TEST_MB_NAMESPACE, topic_name)
      expect(producer5).to be(producer4)
    end

    it "caches consumers, but only for the same subscription" do
      topic_name = "cachable-created-topic-#{SecureRandom.hex(16)}"
      subscription_name_1 = "subscription-1-#{SecureRandom.hex(4)}"
      subscription_name_2 = "subscription-2-#{SecureRandom.hex(4)}"
      consumer1 = MessageBus.consumer_for(TEST_MB_NAMESPACE, topic_name, subscription_name_1)
      consumer2 = MessageBus.consumer_for(TEST_MB_NAMESPACE, topic_name, subscription_name_1)
      consumer3 = MessageBus.consumer_for(TEST_MB_NAMESPACE, topic_name, subscription_name_2)
      consumer4 = MessageBus.consumer_for(TEST_MB_NAMESPACE, topic_name, subscription_name_2)
      expect(consumer1).to be(consumer2)
      expect(consumer3).to be(consumer4)
      expect(consumer1).to_not be(consumer3)
    end
  end
end
