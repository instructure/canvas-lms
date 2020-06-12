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

require 'pact/messages'
require_relative '../pact_config'
require_relative '../../../spec_helper'

Pact::Messages.pact_broker_url = PactConfig.broker_uri

module LiveEvents
  module PactHelper
    include PactConfig

    def self.message_contract_for(consumer, event)
      Pact::Messages.get_message_contract(
        PactConfig::Providers::CANVAS_LMS_LIVE_EVENTS,
        consumer,
        event
      )
    end

    class Event
      attr_reader :event_message, :event_name, :event_settings, :event_subscriber, :stream_client

      def initialize(event_name:, event_subscriber:, event_settings: nil, stream_client: nil) # rubocop:disable Lint/UnusedMethodArgument, Naming/VariableName
        @event_name = event_name
        @event_settings = event_settings || LiveEvents::PactHelper::FakeSettings.new
        @event_subscriber = event_subscriber
        @stream_client = stream_client || LiveEvents::PactHelper::FakeStreamClient.new(@event_settings.kinesis_stream_name)
        initialize_live_events_settings
      end

      def emit_with(&block)
        LiveEvents.clear_context!
        yield block
        run_jobs
        @event_message = stream_client.data.map do |event|
          JSON.parse(event[:data])
        end.find do |msg|
          msg.dig('attributes', 'event_name') == @event_name
        end
      end

      def has_kept_the_contract?
        raise StandardError, 'You must first call "Event#emit_with" before you can assert the contract has been kept.' unless @event_message
        diff = compare_contract_with_live_event
        contract_matches = diff.none?
        print_difference(diff) unless contract_matches
        contract_matches
      end

      private

      def initialize_live_events_settings
        LiveEvents.settings = event_settings
        LiveEvents.stream_client = stream_client
      end

      def compare_contract_with_live_event
        Pact::JsonDiffer.call(contract_message, event_message)
      end

      def contract_message
        # Canvas Live Event Subscribers
        catalog  = PactConfig::LiveEventConsumers::CATALOG
        outcomes = PactConfig::LiveEventConsumers::OUTCOMES
        quiz_lti = PactConfig::LiveEventConsumers::QUIZ_LTI

        case event_subscriber
        when catalog
          LiveEvents::PactHelper.message_contract_for(catalog, event_name)
        when outcomes
          LiveEvents::PactHelper.message_contract_for(outcomes, event_name)
        when quiz_lti
          LiveEvents::PactHelper.message_contract_for(quiz_lti, event_name)
        else
          raise ArgumentError, "Invalid event_subscriber: #{event_subscriber}"
        end
      end

      def print_difference(diff)
        puts Pact::Matchers::UnixDiffFormatter.call(diff)
      end
    end

    class FakeStreamClient
      attr_accessor :data, :stream_name

      def initialize(stream_name)
        @stream_name = stream_name
      end

      def put_records(records:, stream_name:) # rubocop:disable Lint/UnusedMethodArgument
        @data = records
      end
    end

    class FakeSettings
      attr_reader :kinesis_stream_name, :aws_region

      def initialize(kinesis_stream_name: nil, aws_region: nil)
        @kinesis_stream_name = kinesis_stream_name || 'fake_stream'
        @aws_region = aws_region || 'us-east-1'
      end

      def call
        {
          'kinesis_stream_name' => kinesis_stream_name,
          'aws_region' => aws_region
        }
      end
    end
  end
end
