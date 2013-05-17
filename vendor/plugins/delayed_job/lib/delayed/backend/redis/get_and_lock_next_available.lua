local queue, min_priority, max_priority, worker_name, now = unpack(ARGV)
local job_id = find_available(queue, 1, 0, min_priority, max_priority, now)[1]

if job_exists(job_id) then
  -- update the job with locked_by and locked_at
  redis.call('HMSET', Keys.job(job_id), 'locked_by', worker_name, 'locked_at', now)

  -- add the job to the running_jobs set
  redis.call('ZADD', Keys.running_jobs(), now, job_id)
  -- remove the job from the pending jobs queue
  redis.call('ZREM', Keys.queue(queue), job_id)

  -- return the list of job attributes
  return redis.call('HGETALL', Keys.job(job_id))
else
  return {}
end
