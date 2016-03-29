require_relative '../errors'
module Canvas
  class Errors
    class WorkerInfo
      def initialize(worker)
        @worker = worker
      end

      def to_h
        {
          tags: {
            process_type: "BackgroundJob",
            worker_name: @worker.name,
          }
        }
      end

    end
  end
end
