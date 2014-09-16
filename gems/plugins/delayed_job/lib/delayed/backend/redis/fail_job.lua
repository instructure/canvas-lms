local job_id = unpack(ARGV)
local failed_at, queue, strand = unpack(redis.call('HMGET', Keys.job(job_id), 'failed_at', 'queue', 'strand'))

remove_from_queues(job_id, queue, strand)
redis.call('ZADD', Keys.failed_jobs(), failed_at, job_id)
