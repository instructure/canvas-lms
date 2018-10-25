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
            canvas_domain: ENV['CANVAS_DOMAIN']
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
          shard_id: @job.current_shard&.id,
        }
      end
    end
  end
end
