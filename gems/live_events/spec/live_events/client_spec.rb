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

require 'spec_helper'
require 'aws-sdk-kinesis'

describe LiveEvents::Client do
  def stub_config(opts = {})
    allow(LiveEvents::Client).to receive(:config).and_return({
      'kinesis_stream_name' => 'stream',
      'aws_access_key_id' => 'access_key',
      'aws_secret_access_key_dec' => 'secret_key',
      'aws_region' => 'us-east-1'
    })
  end

  class FakeStreamClient
    attr_accessor :data, :stream, :stream_name

    def initialize(stream_name = 'stream')
      @stream_name = stream_name
    end

    def put_records(stream_name:, records:)
      @data = records
      @stream = stream_name
    end
  end

  class LELogger
    def info(data)
      data
    end

    def error(data)
      data
    end
  end

  let(:test_stream_name) { 'my_stream' }
  let(:fclient) { FakeStreamClient.new(test_stream_name) }

  before(:each) do
    stub_config
    LiveEvents.logger = LELogger.new
    LiveEvents.max_queue_size = -> { 100 }
    LiveEvents.stream_client = fclient
    LiveEvents.clear_context!

    @client = LiveEvents::Client.new nil, fclient, test_stream_name
    LiveEvents.worker.start!
  end

  def expect_put_records(payload, stream_client = LiveEvents.stream_client)
    expect(stream_client.data.size).to eq(payload.size)
    expect(JSON.parse(stream_client.data.first[:data])).to eq(payload.first[:data])
    expect(stream_client.data.first[:partition_key]).to eq(payload.first[:partition_key])
    expect(stream_client.stream).to eq test_stream_name
  end

  describe "config" do
    it "should correctly parse the endpoint" do
      res = LiveEvents::Client.aws_config({
        "aws_endpoint" => "http://example.com:6543/"
      })

      expect(res[:endpoint]).to eq("http://example.com:6543/")
      LiveEvents.worker.stop!
    end
  end

  describe "post_event" do
    now = Time.now

    it "should call put_records on the kinesis stream" do
      @client.post_event('event', {}, now, {}, "123")
      LiveEvents.worker.stop!
      expect_put_records([{
        data: {
          "attributes" => {
            "event_name" => 'event',
            "event_time" => now.utc.iso8601(3)
          },
          "body" => {}
        },
        partition_key: "123"
      }])
    end

    it "should include attributes when supplied via ctx" do
      now = Time.now

      @client.post_event('event', {}, now, { user_id: 123, real_user_id: 321, login: 'loginname', user_agent: 'agent' }, 'pkey')
      LiveEvents.worker.stop!
      expect_put_records([{
        data: {
          "attributes" => {
            "event_name" => 'event',
            "event_time" => now.utc.iso8601(3),
            "user_id" => 123,
            "real_user_id" => 321,
            "login" => 'loginname',
            "user_agent" => 'agent'
          },
          "body" => {}
        },
        partition_key: 'pkey'
      }])
    end

    it "should not send blacklisted conxted attributes" do
      now = Time.now
      @client.post_event(
        'event',
        {},
        now,
        { user_id: 123, real_user_id: 321, login: 'loginname', user_agent: 'agent', compact_live_events: true },
        'pkey'
      )
      LiveEvents.worker.stop!
      expect_put_records([{
        data: {
          "attributes" => {
            "event_name" => 'event',
            "event_time" => now.utc.iso8601(3),
            "user_id" => 123,
            "real_user_id" => 321,
            "login" => 'loginname',
            "user_agent" => 'agent'
          },
          "body" => {}
        },
        partition_key: 'pkey'
      }])
    end
  end

  describe "LiveEvents helper" do
    it "should set context info via set_context and send it with events" do
      LiveEvents.set_context({ user_id: 123 })

      now = Time.now

      LiveEvents.post_event(
        event_name: 'event',
        payload: {},
        time: now,
        partition_key: 'pkey'
      )
      LiveEvents.worker.stop!
      expect_put_records([{
        data: {
          "attributes" => {
            "event_name" => 'event',
            "event_time" => now.utc.iso8601(3),
            "user_id" => 123
          },
          "body" => {}
        },
        partition_key: 'pkey'
      }])
    end

    it "should clear context on clear_context!" do
      LiveEvents.set_context({ user_id: 123 })
      LiveEvents.clear_context!

      now = Time.now # rubocop:disable Rails/SmartTimeZone

      LiveEvents.post_event(
        event_name: 'event',
        payload: {},
        time: now,
        partition_key: 'pkey'
      )
      LiveEvents.worker.stop!
      expect_put_records(
        [
          {
            data: {
              "attributes" => {
                "event_name" => 'event',
                "event_time" => now.utc.iso8601(3)
              },
              "body" => {}
            },
            partition_key: 'pkey'
          }
        ]
      )
    end

    context do
      let(:test_stream_name) { 'custom_stream_name' }

      it "should use custom stream client when defined" do
        fake_stream_client = FakeStreamClient.new test_stream_name
        LiveEvents.stream_client = fake_stream_client

        now = Time.now # rubocop:disable Rails/SmartTimeZone

        LiveEvents.post_event(
          event_name: 'event',
          payload: {},
          time: now,
          partition_key: 'pkey'
        )
        LiveEvents.worker.stop!
        expect_put_records(
          [{
            data: {
              "attributes" => {
                "event_name" => 'event',
                "event_time" => now.utc.iso8601(3)
              },
              "body" => {}
            },
            partition_key: 'pkey'
          }],
          fake_stream_client
        )
      end
    end
  end
end
