#
# Copyright (C) 2014 Instructure, Inc.
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
require 'aws-sdk'

describe LiveEvents::Client do
  def stub_config(opts = {})
    allow(LiveEvents::Client).to receive(:config).and_return({
      'kinesis_stream_name' => 'stream',
      'aws_access_key_id' => 'access_key',
      'aws_secret_access_key_dec' => 'secret_key',
      'aws_region' => 'us-east-1'
    })
  end

  before(:each) do
    stub_config
    LiveEvents.logger = double()
    LiveEvents.max_queue_size = -> { 100 }

    @kclient = double()
    allow(Aws::Kinesis::Client).to receive(:new).and_return(@kclient)

    @client = LiveEvents::Client.new
  end

  RSpec::Matchers.define :a_live_events_payload do |payload|
    match do |actual|
      to_compare = actual.merge({ data: JSON.parse(actual[:data]) })
      to_compare == payload
    end
  end

  def expect_put_record(payload)
    expect(@kclient).to receive(:put_record).with(a_live_events_payload(payload))
  end

  describe "config" do
    it "should correctly parse the endpoint" do
      res = LiveEvents::Client.aws_config({
        "aws_endpoint" => "http://example.com:6543/"
      })

      expect(res[:endpoint]).to eq("http://example.com:6543/")
    end
  end

  describe "post_event" do
    now = Time.now

    it "should call put_record on the kinesis stream" do
      expect_put_record({
        stream_name: 'stream',
        data: {
          "attributes" => {
            "event_name" => 'event',
            "event_time" => now.utc.iso8601
          },
          "body" => {}
        },
        partition_key: "123"
      })

      @client.post_event('event', {}, now, {}, "123")

      LiveEvents.worker.stop!
    end

    it "should include attributes when supplied via ctx" do
      now = Time.now

      expect_put_record({
        stream_name: 'stream',
        data: {
          "attributes" => {
            "event_name" => 'event',
            "event_time" => now.utc.iso8601,
            "user_id" => 123,
            "real_user_id" => 321,
            "login" => 'loginname',
            "user_agent" => 'agent'
          },
          "body" => {}
        },
        partition_key: 'pkey'
      })

      @client.post_event('event', {}, now, { user_id: 123, real_user_id: 321, login: 'loginname', user_agent: 'agent' }, 'pkey')
      LiveEvents.worker.stop!
    end
  end

  describe "LiveEvents helper" do
    it "should set context info via set_context and send it with events" do
      LiveEvents.set_context({ user_id: 123 })

      now = Time.now

      expect_put_record({
        stream_name: 'stream',
        data: {
          "attributes" => {
            "event_name" => 'event',
            "event_time" => now.utc.iso8601,
            "user_id" => 123
          },
          "body" => {}
        },
        partition_key: 'pkey'
      })

      LiveEvents.post_event('event', {}, now, nil, 'pkey')
      LiveEvents.worker.stop!
    end

    it "should clear context on clear_context!" do
      LiveEvents.set_context({ user_id: 123 })
      LiveEvents.clear_context!

      now = Time.now

      expect_put_record({
        stream_name: 'stream',
        data: {
          "attributes" => {
            "event_name" => 'event',
            "event_time" => now.utc.iso8601
          },
          "body" => {}
        },
        partition_key: 'pkey'
      })

      LiveEvents.post_event('event', {}, now, nil, 'pkey')
      LiveEvents.worker.stop!
    end
  end
end

