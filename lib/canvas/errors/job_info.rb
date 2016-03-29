require_relative '../errors'
module Canvas
  class Errors
    class JobInfo
      def initialize(job, worker)
        @job = job
        @worker = worker
      end

      def to_h
        {
          tags: {
            process_type: "BackgroundJob",
            job_tag: @job.tag,
          },
          extra: extras_hash
        }
      end

      private
      def extras_hash
        {
          id: @job.id,
          source: @job.source,
          attempts: @job.attempts,
          strand: @job.strand,
          priority: @job.priority,
          worker_name: @worker.name,
          handler: @job.handler,
          run_at: @job.run_at,
          max_attempts: @job.max_attempts,
        }
      end
    end
  end
end
