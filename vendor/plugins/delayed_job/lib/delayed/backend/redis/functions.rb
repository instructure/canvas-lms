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

# This module handles loading the Lua functions into Redis and running them
module Delayed::Backend::Redis
class Functions
  class Script < Struct.new(:text, :sha)
  end

  def self.script_include
    @script_include ||= File.read(File.dirname(__FILE__) + "/include.lua")
  end

  def logger
    ActiveRecord::Base.logger
  end

  def log_timing(name)
    result = nil
    ms = Benchmark.ms { result = yield }
    if logger && logger.debug?
      line = 'Redis Jobs Timing: %s (%.1fms)' % [name, ms]
      logger.debug(line)
    end
    result
  end

  # The map of <script name> -> <script text>
  # If the script isn't already loaded, this will load it and prepend include.lua to it
  SCRIPTS = Hash.new do |hash, key|
    filename = File.dirname(__FILE__) + "/#{key}.lua"
    if File.file?(filename)
      hash[key] = Script.new(Delayed::Backend::Redis::Functions.script_include + "\n\n" + File.read(filename))
    end
  end

  # Run the given script, passing in the given keys and args
  # If the script isn't already loaded into redis, this will catch the error,
  # load it in, then run it again, giving up after a couple tries.
  def run_script(redis, script_name, keys, argv)
    script = SCRIPTS[script_name]
    raise(ArgumentError, "unknown script: #{script_name}") unless script

    if !script.sha
      script.sha = redis.script(:load, script.text)
    end

    attempts = 0

    log_timing(script_name) do
      begin
        attempts += 1
        redis.evalsha(script.sha, :keys => keys, :argv => argv)
      rescue Redis::CommandError => e
        raise unless e.message =~ /NOSCRIPT/ && attempts <= 2
        script.sha = redis.script(:load, script.text)
        retry
      end
    end
  end

  def find_available(redis, queue, limit, offset, min_priority, max_priority, now)
    run_script(redis, :find_available, [], [queue, limit, offset, min_priority, max_priority, now.utc.to_f])
  end

  def get_and_lock_next_available(redis, worker_name, queue, min_priority, max_priority, now)
    attrs = run_script(redis, :get_and_lock_next_available, [], [queue, min_priority, max_priority, worker_name, now.utc.to_f])
    Hash[*attrs]
  end

  def enqueue(redis, job_id, queue, strand, now)
    run_script(redis, :enqueue, [], [job_id, queue, strand, now.utc.to_f])
  end

  def destroy_job(redis, job_id, now)
    run_script(redis, :destroy_job, [], [job_id, now.utc.to_f])
  end

  def tickle_strand(redis, job_id, strand, now)
    run_script(redis, :tickle_strand, [], [job_id, strand, now.utc.to_f])
  end

  def create_singleton(redis, job_id, queue, strand, now)
    run_script(redis, :enqueue, [], [job_id, queue, strand, now.utc.to_f, true])
  end

  def fail(redis, job_id)
    run_script(redis, :fail, [], [job_id])
  end

  def set_running(redis, job_id)
    run_script(redis, :set_running, [], [job_id])
  end

  def bulk_update(redis, action, ids, flavor, query, now)
    ids = (ids || []).join(",")
    run_script(redis, :bulk_update, [], [action, ids, flavor, query, now.utc.to_f])
  end

end
end
