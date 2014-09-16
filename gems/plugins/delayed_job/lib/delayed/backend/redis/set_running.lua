local job_id = unpack(ARGV)
local locked_at, queue, strand = unpack(redis.call('HMGET', Keys.job(job_id), 'locked_at', 'queue', 'strand'))

remove_from_queues(job_id, queue, strand)
redis.call('ZADD', Keys.running_jobs(), locked_at, job_id)
