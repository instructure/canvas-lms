# frozen_string_literal: true

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

module CanvasErrors
  ##
  # JobInfo is the mapping from contextual information
  # on inst-jobs primitives to a hash of useful elements to
  # be propogated into any error callback.
  class JobInfo
    def initialize(job, worker)
      @job = job
      @worker = worker
    end

    def to_h
      {
        tags: {
          process_type: "BackgroundJob",
          job_tag: @job.try(:tag),
        },
        extra: extras_hash
      }
    end

    private
    def extras_hash
      # if the shape of a job changes, we don't want to hard-fail.
      # ATTEMPT to extract these values, but silently use nil
      # if it's not possible, better less context then a failed report.
      {
        id: @job.try(:id),
        source: @job.try(:source),
        attempts: @job.try(:attempts),
        strand: @job.try(:strand),
        priority: @job.try(:priority),
        # sometimes we might be reporting these in a context
        # where there is no worker available, and we just
        # pull the current job from the thread context
        worker_name: @worker&.name,
        handler: @job.try(:handler),
        run_at: @job.try(:run_at),
        max_attempts: @job.try(:max_attempts),
        shard_id: @job.try(:current_shard)&.id,
      }
    end
  end
end

