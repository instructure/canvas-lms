# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe LiveEvents::AsyncWorker do
  let(:put_records_return) { [] }
  let(:stream_client) { double(stream_name:) }
  let(:stream_name) { "stream_name_x" }
  let(:event_name) { "event_name" }
  let(:statsd_double) { double(increment: nil) }
  let(:event) do
    {
      event_name:,
      event_time: Time.now.utc.iso8601(3),
      attributes:,
      body: payload
    }
  end
  let(:partition_key) { SecureRandom.uuid }
  let(:payload) do
    {
      event: 1234
    }
  end
  let(:attributes) do
    {
      event_name: "event1"
    }
  end

  before do
    LiveEvents.max_queue_size = -> { 100 }
    LiveEvents.statsd = nil
    allow(LiveEvents).to receive(:logger).and_return(double(info: nil, error: nil, debug: nil))
    @worker = LiveEvents::AsyncWorker.new(false, stream_client:, stream_name:)
    allow(@worker).to receive(:at_exit)
    expect(LiveEvents.logger).to_not receive(:error).with(/Exception making LiveEvents async call/)
    LiveEvents.statsd = statsd_double
    allow(statsd_double).to receive(:time).and_yield
  end

  after do
    LiveEvents.statsd = nil
  end

  describe "push" do
    it "executes stuff pushed on the queue" do
      results_double = double
      results = OpenStruct.new(records: results_double)
      expect(results_double).to receive(:each_with_index).and_return([])
      allow(stream_client).to receive(:put_records).and_return(results)

      @worker.push event, partition_key

      @worker.start!
      @worker.stop!
    end

    it "batches write" do
      results_double = double
      results = OpenStruct.new(records: results_double)
      expect(results_double).to receive(:each_with_index).and_return([])
      allow(stream_client).to receive(:put_records).once.and_return(results)
      @worker.start!

      4.times { @worker.push event, partition_key }

      @worker.stop!
    end

    it "times batch write" do
      results_double = double
      results = OpenStruct.new(records: results_double)
      allow(results_double).to receive(:each_with_index).and_return([])
      allow(stream_client).to receive(:put_records).once.and_return(results)

      expect(statsd_double).to receive(:time).once.and_yield

      @worker.start!

      4.times { @worker.push event, partition_key }

      @worker.stop!
    end

    it "rejects items when queue is full" do
      LiveEvents.max_queue_size = -> { 5 }
      5.times { expect(@worker.push(event, partition_key)).to be_truthy }

      expect(@worker.push(event, partition_key)).to be false
    end

    context "with error putting to kinesis" do
      let(:expected_batch) { { records: [{ data: /1234/, partition_key: instance_of(String) }], stream_name: "stream_name_x" } }

      it "puts 'InternalFailure' records back in the queue for 1 extra retry that passes" do
        results1 = double(records: [double(error_code: "InternalFailure", error_message: "internal failure message")])
        results2 = double(records: [double(error_code: nil)])

        expect(stream_client).to receive(:put_records).with(expected_batch).and_return(results1, results2)
        expect(statsd_double).to receive(:time).and_yield.twice
        expect(statsd_double).not_to receive(:increment).with("live_events.events.send_errors", any_args)
        expect(statsd_double).to receive(:increment).with("live_events.events.sends", any_args)
        expect(statsd_double).to receive(:increment).with("live_events.events.retry", any_args)

        @worker.start!
        @worker.push event, partition_key
        @worker.stop!
      end

      it "puts 'InternalFailure' records back in the queue for 3 retries that fail" do
        results = double(records: [double(error_code: "InternalFailure", error_message: "internal failure message")])

        expect(stream_client).to receive(:put_records).exactly(4).times.and_return(results)
        expect(statsd_double).to receive(:time).and_yield.exactly(4).times
        expect(statsd_double).to receive(:increment).exactly(3).times.with("live_events.events.retry", any_args)
        expect(statsd_double).to receive(:increment).once.with("live_events.events.final_retry", any_args)
        expect(statsd_double).to receive(:increment).with("live_events.events.send_errors", any_args)

        @worker.start!
        @worker.push event, partition_key
        @worker.stop!
      end

      it "writes errors to logger" do
        results = OpenStruct.new(records: [
                                   OpenStruct.new(error_code: "failure", error_message: "failure message")
                                 ])
        allow(stream_client).to receive(:put_records).once.and_return(results)
        expect(statsd_double).to receive(:time).and_yield
        expect(statsd_double).to receive(:increment).with("live_events.events.send_errors", any_args)
        @worker.start!

        4.times { @worker.push event, partition_key }

        @worker.stop!
      end
    end
  end

  describe "exit handling" do
    it "drains the queue" do
      skip("flaky spec needs fixed in PLAT-5106")
      @worker.push(event, partition_key)
      expect(@worker).to receive(:at_exit).and_yield
      expect(LiveEvents.logger).not_to receive(:error)
      @worker.start!
      @worker.send(:at_exit)
    end
  end
end
