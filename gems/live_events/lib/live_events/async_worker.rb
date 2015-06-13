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

module LiveEvents

  # TODO: Consider refactoring out common functionality from this and
  # CanvasPandaPub::AsyncWorker. Their semantics are a bit different so
  # it may not make sense.

  # TODO: Consider adding batched requests. Kinesis has a put_records call
  # that is more efficient. (Would also require using aws-sdk-v2 instead of v1.)
  #
  # If we do that, we'll want to add an at_exit handler that flushes out the
  # queue for cases when the process is shutting down.

  class AsyncWorker
    def initialize(start_thread = true)
      @queue = Queue.new
      @logger = LiveEvents.logger

      self.start! if start_thread
    end

    def push(p)
      if @queue.length >= LiveEvents.max_queue_size
        return false
      end

      @queue << p
      true
    end

    def stopped?
      @thread.nil? || !@thread.alive?
    end

    def stop!
      @queue << :stop
      @thread.join
    end

    def start!
      @thread = Thread.new { self.run_thread }
    end

    def run_thread
      loop do
        p = @queue.pop

        break if p == :stop

        begin
          p.call
        rescue Exception => e
          @logger.error("Exception making LiveEvents async call: #{e}")
        end
      end
    end
  end
end

