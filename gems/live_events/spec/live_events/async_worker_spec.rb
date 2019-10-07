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

require 'spec_helper'

describe LiveEvents::AsyncWorker do
  let(:put_records_return) { [] }
  let(:stream_client) { double(stream_name: stream_name) }
  let(:stream_name) { 'stream_name_x' }
  let(:event_name) { 'event_name' }
  let(:event) do
    {
      event_name: event_name,
      event_time: Time.now.utc.iso8601(3),
      attributes: attributes,
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
      event_name: 'event1'
    }
  end

  class LELogger
    def info(data)
      data
    end

    def error(data)
      data
    end

    def debug(data)
      data
    end
  end

  before(:each) do
    LiveEvents.max_queue_size = -> { 100 }
    LiveEvents.statsd = nil
    LiveEvents.logger = LELogger.new
    @worker = LiveEvents::AsyncWorker.new(false, stream_client: stream_client, stream_name: stream_name)
    allow(@worker).to receive(:at_exit)
  end

  after(:each) do
    LiveEvents.statsd = nil
  end

  describe "push" do
    it "should execute stuff pushed on the queue" do
      results_double = double
      results = OpenStruct.new(records: results_double)
      expect(results_double).to receive(:each_with_index).and_return([])
      allow(stream_client).to receive(:put_records).and_return(results)

      @worker.push event, partition_key

      @worker.start!
      @worker.stop!
    end

    it "should batch write" do
      results_double = double
      results = OpenStruct.new(records: results_double)
      expect(results_double).to receive(:each_with_index).and_return([])
      allow(stream_client).to receive(:put_records).once.and_return(results)
      @worker.start!

      4.times { @worker.push event, partition_key }

      @worker.stop!
    end

    it "should time batch write" do
      results_double = double
      results = OpenStruct.new(records: results_double)
      allow(results_double).to receive(:each_with_index).and_return([])
      allow(stream_client).to receive(:put_records).once.and_return(results)
      statsd_double = double
      LiveEvents.statsd = statsd_double
      expect(statsd_double).to receive(:time).and_yield
      @worker.start!

      4.times { @worker.push event, partition_key }

      @worker.stop!
    end

    it "should reject items when queue is full" do
      LiveEvents.max_queue_size = -> { 5 }
      5.times { expect(@worker.push(event, partition_key)).to be_truthy }

      expect(@worker.push(event, partition_key)).to be false
    end

    context 'with error putting to kinesis' do
      it "should write errors to logger" do
        results = OpenStruct.new(records: [
          OpenStruct.new(error_code: 'failure', error_message: 'failure message')
        ])
        allow(stream_client).to receive(:put_records).once.and_return(results)
        statsd_double = double
        LiveEvents.statsd = statsd_double
        expect(statsd_double).to receive(:time).and_yield
        expect(statsd_double).to receive(:increment).with('live_events.events.send_errors', any_args)
        @worker.start!

        4.times { @worker.push event, partition_key }

        @worker.stop!
      end
    end
  end

  describe "exit handling" do
    it "should drain the queue" do
      @worker.push(event, partition_key)
      expect(@worker).to receive(:at_exit).and_yield
      @worker.start!
      @worker.send(:at_exit)
    end
  end
end
