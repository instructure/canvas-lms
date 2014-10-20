#
# Copyright (C) 2012 Instructure, Inc.
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

require 'redis/scripting'

# This module handles loading the Lua functions into Redis and running them
module Delayed::Backend::Redis
class Functions < ::Redis::Scripting::Module
  def initialize(redis)
    super(redis, File.dirname(__FILE__))
  end

  def run_script(script, keys, argv)
    result = nil
    ms = Benchmark.ms { result = super }
    line = 'Redis Jobs Timing: %s (%.1fms)' % [script.name, ms]
    ActiveRecord::Base.logger.debug(line)
    result
  end

  def find_available(queue, limit, offset, min_priority, max_priority, now)
    run(:find_available, [], [queue, limit, offset, min_priority, max_priority, now.utc.to_f])
  end

  def get_and_lock_next_available(worker_name, queue, min_priority, max_priority, now)
    attrs = run(:get_and_lock_next_available, [], [queue, min_priority, max_priority, worker_name, now.utc.to_f])
    Hash[*attrs]
  end

  def enqueue(job_id, queue, strand, now)
    run(:enqueue, [], [job_id, queue, strand, now.utc.to_f])
  end

  def create_singleton(job_id, queue, strand, now)
    run(:enqueue, [], [job_id, queue, strand, now.utc.to_f, true])
  end

  def destroy_job(job_id, now)
    run(:destroy_job, [], [job_id, now.utc.to_f])
  end

  def tickle_strand(job_id, strand, now)
    run(:tickle_strand, [], [job_id, strand, now.utc.to_f])
  end

  def fail_job(job_id)
    run(:fail_job, [], [job_id])
  end

  def set_running(job_id)
    run(:set_running, [], [job_id])
  end

  def bulk_update(action, ids, flavor, query, now)
    ids = (ids || []).join(",")
    run(:bulk_update, [], [action, ids, flavor, query, now.utc.to_f])
  end

end
end
