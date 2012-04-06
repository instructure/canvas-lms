module Delayed
  module Batch
    class PerformableBatch < Struct.new(:mode, :items)
      def initialize(mode, items)
        raise "unsupported mode" unless mode == :serial
        self.mode   = mode
        self.items  = items
      end

      def display_name
        "Delayed::Batch.#{mode}"
      end
      alias_method :tag, :display_name
      alias_method :full_name, :display_name

      def perform
        raise "can't perform a batch directly"
      end

      def jobs
        items.map { |opts| Delayed::Job.new(opts) }
      end
    end

    class << self
      def serial_batch
        prepare_batches(:serial){ yield }
      end

      private
      def prepare_batches(mode)
        raise "nested batching is not supported" if Delayed::Job.batches
        Delayed::Job.batches = Hash.new { |h,k| h[k] = [] }
        yield
      ensure
        batches = Delayed::Job.batches
        Delayed::Job.batches = nil
        batches.each do |enqueue_args, batch|
          Delayed::Job.enqueue(Delayed::Batch::PerformableBatch.new(mode, batch), enqueue_args)
        end
      end
    end
  end
end
