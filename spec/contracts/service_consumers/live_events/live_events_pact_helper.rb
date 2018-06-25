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

    class Event
      attr_reader :event_message, :event_name, :event_settings, :event_subscriber, :stream_client

      def initialize(event_name:, event_subscriber:, event_settings: nil, stream_client: nil) # rubocop:disable Lint/UnusedMethodArgument, Naming/VariableName
        @event_name = event_name
        @event_settings = event_settings || LiveEvents::PactHelper::FakeSettings.new
        @event_subscriber = event_subscriber
        @stream_client = stream_client || LiveEvents::PactHelper::FakeStreamClient.new
        initialize_live_events_settings
      end

      def emit_with(&block)
        LiveEvents.clear_context!
        yield block
        run_jobs
        @event_message = stream_client.data
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
        case event_subscriber
        when PactConfig::Consumers::QUIZ_LTI
          LiveEvents::PactHelper.quiz_lti_contract_for(event_name)
        else
          raise ArgumentError, "Invalid event_subscriber: #{event_subscriber}"
        end
      end

      def print_difference(diff)
        puts Pact::Matchers::UnixDiffFormatter.call(diff)
      end
    end

    class FakeStreamClient
      attr_accessor :data

      def put_record(stream_name:, data:, partition_key:) # rubocop:disable Lint/UnusedMethodArgument
        @data = JSON.parse(data)
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

    class << self
      def quiz_lti_contract_for(event)
        message_contract_for(PactConfig::Consumers::QUIZ_LTI, event)
      end

      private

      def message_contract_for(consumer, event)
        Pact::Messages.get_message_contract(
          PactConfig::Providers::CANVAS_LMS_LIVE_EVENTS,
          consumer,
          event
        )
      end
    end
  end
end
