local job_id, queue, strand, now, for_singleton = unpack(ARGV)
local strand_key = Keys.strand(strand)

-- if this is a singleton job, only queue it up if another doesn't exist on the strand
-- otherwise, delete it and return the other job id
if for_singleton then
  local job_ids = redis.call('LRANGE', strand_key, 0, 1)
  local job_to_check = 1
  if job_exists(job_ids[1]) and redis.call('HGET', Keys.job(job_ids[1]), 'locked_at') then
    job_to_check = 2
  end

  local job_to_check_id = job_ids[job_to_check]
  if job_exists(job_to_check_id) then
    -- delete the new job, we found a match
    redis.call('DEL', Keys.job(job_id))
    return job_to_check_id
  end
end

-- if this job is in a strand, add it to the strand queue first
-- if it's not at the front of the strand, we won't enqueue it below
if strand_key then
  add_to_strand(job_id, strand)
end

add_to_queues(job_id, queue, now)

return job_id
