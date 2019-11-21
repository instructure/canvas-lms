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

require 'inst_statsd'

module LiveEvents
  class << self
    attr_accessor :logger, :cache, :statsd
    attr_reader :stream_client

    # rubocop:disable Style/TrivialAccessors
    def settings=(settings)
      @settings = settings
    end

    def settings
      @settings.call
    end

    def max_queue_size=(size)
      @max_queue_size = size
    end

    def max_queue_size
      @max_queue_size.call
    end
    # rubocop:enable Style/TrivialAccessors

    require 'live_events/client'
    require 'live_events/async_worker'

    def get_context
      Thread.current[:live_events_ctx].try(:clone)
    end

    # Set (on the current thread) the context to be used for future calls to post_event.
    def set_context(ctx)
      Thread.current[:live_events_ctx] = ctx
    end

    def clear_context!
      Thread.current[:live_events_ctx] = nil
    end

    # Post an event for the current account.
    def post_event(event_name:, payload:, time: Time.now, context: nil, partition_key: nil) # rubocop:disable Rails/SmartTimeZone
      if (LiveEvents::Client.config)
        context ||= Thread.current[:live_events_ctx]
        client.post_event(event_name, payload, time, context, partition_key)
      end
    end

    def truncate(string)
      if string
        string.truncate(Setting.get('live_events_text_max_length', 8192).to_i, separator: ' ')
      end
    end

    def worker
      if !@launched_pid || @launched_pid != Process.pid || @worker.stopped?
        if @launched_pid && @launched_pid != Process.pid
          logger.warn "Starting new LiveEvents worker thread due to fork."
        end

        @worker = LiveEvents::AsyncWorker.new(stream_client: client.stream_client, stream_name: client.stream_name)
        @launched_pid = Process.pid
      end

      @worker
    end

    def stream_client=(s_client)
      @old_stream_client = @stream_client
      @stream_client = s_client
    end

    private

    def client
      if @client && !new_client?
        @client
      else
        @client = LiveEvents::Client.new(LiveEvents::Client.config, @stream_client, @stream_client&.stream_name, worker: @worker)
      end
    end

    def new_client?
      return true if @old_stream_client != @stream_client
      @config ||= LiveEvents::Client.config
      if @config != LiveEvents::Client.config
        @config = LiveEvents::Client.config
        true
      end
      false
    end
  end
end
