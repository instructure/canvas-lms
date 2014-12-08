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

require 'canvas_http'

module CanvasPandaPub
  class << self
    attr_accessor :logger, :cache

    def plugin_settings=(settings)
      @plugin_settings = settings
    end

    def plugin_settings
      @plugin_settings.call
    end

    def max_queue_size=(size)
      @max_queue_size = size
    end

    def max_queue_size
      @max_queue_size.call
    end

    def process_interval=(interval)
      @process_interval = interval
    end

    def process_interval
      @process_interval.call
    end

    require 'canvas_panda_pub/async_worker'
    require 'canvas_panda_pub/client'

    # Returns true if PandaPub is currently enabled.

    def enabled?
      !!CanvasPandaPub::Client.config
    end

    # Post an update to a PandaPub channel.
    #
    # Helper for the `post_update` Client instance method. Creates a
    # Client and calls the `post_update` method with the supplied
    # arguments. See CanvasPandaPub::Client#post_update for details.
    #
    # This is a noop if PandaPub is not currently configured.

    def post_update(channel, payload)
      if CanvasPandaPub.enabled?
        CanvasPandaPub::Client.new.post_update(channel, payload)
      end
    end

    # Generate a token for subscribing to a channel.
    #
    # Convenience helper for CanvasPandaPub::Client#generate_token.
    #
    # Returns nil if PandaPub is not configured.

    def generate_token(channel, read = false, write = false, expires = 1.hour.from_now)
      if CanvasPandaPub.enabled?
        CanvasPandaPub::Client.new.generate_token(channel, read, write, expires)
      end
    end

    # Internal: Creates and/or returns a worker process for sending out
    # http requests.

    def worker
      if !@launched_pid || @launched_pid != Process.pid
        if @launched_pid
          logger.warn "Starting new PandaPub worker thread due to fork."
        end

        @worker = CanvasPandaPub::AsyncWorker.new
        @launched_pid = Process.pid
      end
      @worker
    end
  end
end
