# frozen_string_literal: true

# Copyright (C) 2021 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it \under
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

module MessageBus
  ##
  # thrown if production to the pulsar instance is so
  # throttled that the queue has grown to the max size
  # and we're still trying to push new messages on.
  # Better to have a max queue size and exhibit back
  # pressure predictably than to have an unbounded queue
  # (in which case memory consumption could grow until
  #  it became significant enough to impede general request
  # servicing).
  class MemoryQueueFullError < StandardError; end

  # Internal: Background worker for queueing up
  # writes to the pulsar message bus in memory.
  # this should help prevent operational issues on
  # the pulsar side from creating too much backpressure
  # at the canvas level.  Note that messages written this
  # way have less guarantees about making it to pulsar than ones
  # written synchronously (which will error if they fail).
  # A catastrophic machine failure could dump events still in
  # the memory queue.
  class AsyncProducer
    def initialize(start_thread: true)
      Bundler.require(:pulsar)
      @queue = Queue.new
      @logger = MessageBus.logger
      @interval = MessageBus.worker_process_interval

      self.start! if start_thread
    end

    def push(namespace, topic_name, message)
      if queue_depth >= MessageBus.max_mem_queue_size
        raise ::MessageBus::MemoryQueueFullError, "Pulsar throughput constrained, queue full"
      end

      # although it's possible for Shard.current to take a db connection
      # this action should be happening either inside the parent thread directly
      # (in which case we're fine to checkout a connection for that thread)
      # or as an error handler during processing, in which case we should already have
      # a leased connection within this thread on the default shard and be inside an executor context.
      # yes, that means multiple threads may address this data structure,
      # but ruby queues are threadsafe (https://ruby-doc.org/core-2.5.0/Queue.html).
      @queue << [namespace, topic_name, message, Shard.current.id]
    end

    def queue_depth
      @queue.length
    end

    def stop!
      @queue << :stop
      # the background thread may block on autoloading constants
      # in isolated dev/test cases in which case we need to not deadlock here.
      # https://guides.rubyonrails.org/threading_and_code_execution.html#permit-concurrent-loads
      ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
        @thread.join
      end
    end

    def start!
      @thread = Thread.new { self.run_thread }
    end

    def run_thread
      stop = false

      loop do
        # We let push requests build up every interval, and then coalesce.
        # This gives us some cheap throttling.
        sleep @interval # rubocop:disable Lint/NoSleep

        # Block until an item shows up, and attempt
        # to process it.
        status = process_one_queue_item
        stop = (status == :stop)
        break if stop
        # process failure should be taken as a throttle cue,
        # so let the thread sleep another interval before
        # trying again.
        next unless status == :success

        # we succeeded once, let's try to drain the queue.
        # New items may show up (so this
        # doesn't completely empty the queue) but that's fine - if we kept
        # popping until empty, we could theoretically end up popping forever.
        queue_batch_remaining_count = @queue.length
        while queue_batch_remaining_count > 0
          status = process_one_queue_item
          if status != :success
            stop = (status == :stop)
            # if we get an error, that means either it was retriable
            # and failed, or it wasn't one we recognized.  The message
            # should have gone back on the queue, but we shouldn't try
            # to keep pulling new messages.
            break
          end
          queue_batch_remaining_count -= 1
        end

        break if stop

        # make sure we release any resources before
        # the thread sleeps
        MessageBus.on_work_unit_end&.call
      end
    end

    def process_one_queue_item
      work_tuple = @queue.pop
      return :stop if work_tuple == :stop

      status = :none
      namespace, topic_name, message, shard_id = *work_tuple
      # ensure any autoloading or other thread-aware operations
      # in our framework invocations have the right hooks into the
      # thread context.  If we make calls to rails framework items
      # outside this block, the scope of the wrapping needs to be
      # expanded. https://guides.rubyonrails.org/threading_and_code_execution.html#wrapping-application-code
      Rails.application.executor.wrap do
        Shard.lookup(shard_id).activate do
          begin
            status = produce_message(namespace, topic_name, message)
          rescue StandardError => e
            # if we errored, we didn't actually process the message
            # put it back on the queue to try to get to it later.
            # Does this screw up ordering?  yes, absolutely, but ruby queues are one-way.
            # If your messages within topics are required to be stricly ordered, you need to
            # generate a producer and manage error handling yourself.
            @queue.push(work_tuple)
            # if this is NOT one of the known error types from pulsar
            # then we actually need to know about it with a full ":error"
            # level in sentry.
            err_level = ::MessageBus.rescuable_pulsar_errors.include?(e.class) ? :warn : :error
            CanvasErrors.capture_exception(:message_bus, e, err_level)
            status = :error
          ensure
            MessageBus.on_work_unit_end&.call
          end
        end
      end
      status
    end

    def produce_message(namespace, topic_name, message)
      retries = 0
      begin
        producer = MessageBus.producer_for(namespace, topic_name)
        producer.send(message)
      rescue *::MessageBus.rescuable_pulsar_errors => e
        # We'll retry this exactly one time.  Sometimes
        # when a pulsar broker restarts, we have connections
        # that already knew about that broker get into a state where
        # they just timeout or fail instead of reconfiguring.  Often this can
        # be cleared by just rebooting the process, but that's overkill.
        # If we hit a timeout, we will try one time to dump all the client
        # context and reconnect.  If we get a timeout again, that is NOT
        # the problem, and we should let the error raise.
        retries += 1
        raise e if retries > 1

        Rails.logger.info "[AUA] Pulsar failure during message send, retrying..."
        CanvasErrors.capture_exception(:message_bus, e, :warn)
        MessageBus.reset!
        retry
      end
      :success
    end
  end
end
