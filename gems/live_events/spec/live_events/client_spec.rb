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

require 'spec_helper'
require 'aws-sdk-kinesis'

describe LiveEvents::Client do
  def stub_config
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

    def warn(data)
      data
    end
  end

  let(:test_stream_name) { 'my_stream' }
  let(:fclient) { FakeStreamClient.new(test_stream_name) }

  def prep_client_and_worker
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

  describe ".aws_config" do
    before { prep_client_and_worker }

    it "parses the endpoint correctly" do
      res = LiveEvents::Client.aws_config({
                                            "aws_endpoint" => "http://example.com:6543/"
                                          })

      expect(res[:endpoint]).to eq("http://example.com:6543/")
      LiveEvents.worker.stop!
    end

    it "ignores invalid endpoints" do
      res = LiveEvents::Client.aws_config({
                                            "aws_endpoint" => "example.com:6543/"
                                          })

      expect(res.key?(:endpoint)).to eq false
      LiveEvents.worker.stop!
    end

    it "loads custom creds" do
      LiveEvents.aws_credentials = ->(settings) {
        settings['value_to_return']
      }

      res = LiveEvents::Client.aws_config({
                                            'custom_aws_credentials' => 'true',
                                            'value_to_return' => 'a_value'
                                          })

      expect(res[:credentials]).to eq('a_value')
      LiveEvents.worker.stop!
    end
  end

  describe ".config" do
    subject { LiveEvents::Client.config }
    before { allow(LiveEvents).to receive(:settings).and_return(settings) }

    let(:settings) do
      {
        'aws_region' => 'us-east-1',
        'kinesis_stream_name' => 'abc',
      }
    end

    context 'when custom_aws_crendentials is present' do
      let(:settings) { super().merge('custom_aws_credentials' => true) }

      it { is_expected.to eq(settings) }
    end

    context 'when no custom_aws_credentials or aws access key are given' do
      let(:settings) { super().merge('aws_secret_access_key_dec' => 'foo') }

      it { is_expected.to be_nil }
    end

    context 'when no custom_aws_credentials or aws secret key are given' do
      let(:settings) { super().merge('aws_access_key_id' => 'bar') }

      it { is_expected.to be_nil }
    end

    if defined?(Rails)
      context 'when running in prod even with no custom_aws_credentials or aws access/secret key' do
        before { allow(Rails.env).to receive(:production?).and_return(true) }

        it { is_expected.to eq(settings) }
      end
    end

    context 'when aws access and secret key are given' do
      let(:settings) do
        super().merge('aws_secret_access_key_dec' => 'foo', 'aws_access_key_id' => 'bar')
      end

      it { is_expected.to eq(settings) }
    end
  end

  describe "post_event" do
    before { prep_client_and_worker }

    it "calls put_records on the kinesis stream" do
      now = Time.now

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

    it "includes attributes when supplied via ctx" do
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

    it "does not send blacklisted conxted attributes" do
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
    before { prep_client_and_worker }

    it "sets context info via set_context and send it with events" do
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

    it "clears context on clear_context!" do
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

      it "uses custom stream client when defined" do
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
