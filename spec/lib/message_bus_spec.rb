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

require 'spec_helper'

describe MessageBus do
  TEST_MB_NAMESPACE = "test-only"

  before(:each) do
    skip("pulsar config required to test") unless MessageBus.enabled?
  end

  after(:each) do
    MessageBus.reset!
  end

  it "can send messages and then later receive messages" do
    topic_name = "lazily-created-topic-#{SecureRandom.hex(16)}"
    subscription_name = "subscription-#{SecureRandom.hex(4)}"
    producer = MessageBus.producer_for(TEST_MB_NAMESPACE, topic_name)
    log_values = {test_key: "test_val"}
    producer.send(log_values.to_json)
    consumer = MessageBus.consumer_for(TEST_MB_NAMESPACE, topic_name, subscription_name)
    msg = consumer.receive(1000)
    consumer.acknowledge(msg)
    # normally you would process the message before acknowledging it
    # but we're trying to keep the external state as clean as possible in the tests.
    expect(JSON.parse(msg.data)['test_key']).to eq("test_val")
  end

  it "only parses the YAML one time as long as it doesn't change" do
    # make sure we aren't parsing every time
    expect(YAML).to receive(:safe_load).at_most(:twice).and_call_original
    original_config = nil
    5.times { original_config = MessageBus.config }
    # force the config to change, so we get a second yaml parse
    yaml = "NOT_THE_ORIGINAL: config"
    allow(DynamicSettings).to receive(:find).and_return({'pulsar.yml' => yaml})
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
