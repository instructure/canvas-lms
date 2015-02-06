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

require 'thread'
require 'set'

module CanvasPandaPub

  # Internal: Helper for performing PandaPub HTTP requests in a separate
  # thread. The only type of pushes we currently support are ones where later
  # pushes take precedence over earlier pushes.

  class AsyncWorker

    def initialize(start_thread = true)
      @queue = Queue.new
      @logger = CanvasPandaPub.logger
      @interval = CanvasPandaPub.process_interval

      self.start! if start_thread
    end

    def push(tag, p)
      if @queue.length >= CanvasPandaPub.max_queue_size
        return false
      end

      # first element is the channel
      # second the Proc that gets run
      # third is a flag of whether or not to actually run it. We may
      # change it to false later
      @queue << [ tag, p, true ]
      true
    end

    def stop!
      @queue << :stop
      @thread.join
    end

    def start!
        @thread = Thread.new { self.run_thread }
    end

    def run_thread
      stop = false

      loop do
        work = []

        # We let push requests build up every interval, and then coalesce.
        # This gives us some cheap throttling.
        sleep @interval

        # Block until an item shows up...
        work << @queue.pop

        # .. then pop items off the queue. New items may show up (so this
        # doesn't completely empty the queue) but that's fine - if we kept
        # popping until empty, we could theoretically end up popping forever.
        @queue.length.times do
          work << @queue.pop
        end

        # Mark all but the last instance of each tag as "false" to not
        # execute. Doing it this way, rather than building up a Hash of
        # channel -> p, keeps ordering such that each item of work
        # will be executed in the order it was queued. It also gives
        # future flexibility for adding more modes (like pushing all updates,
        # instead of just the most recent).
        seen_channels = Set.new
        work.reverse.each do |ary|
          if seen_channels.include? ary[0]
            ary[2] = false
          else
            seen_channels << ary[0]
          end
        end

        work.each do |ary|
          if ary == :stop
            stop = true
            break
          end

          tag, p, execute = *ary
          next unless execute

          begin
            # We could use Canvas.timeout_protection here, but I'd rather not
            # since a) that incurs a Redis hit for every use, and b) we're
            # already protected from blocking Canvas since we're in a thread.
            p.call
          rescue Exception => e
            @logger.error("Exception making PandaPub call to channel #{tag}: #{e}")
          end
        end

        break if stop
      end
    end
  end
end
