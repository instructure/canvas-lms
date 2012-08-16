-- Keys holds the various functions to map to redis keys
-- These are duplicated from job.rb
local Keys = {}

Keys.job = function(id)
  return "job/" .. id
end

Keys.running_jobs = function()
  return "running_jobs"
end

Keys.failed_jobs = function()
  return "failed_jobs"
end

Keys.queue = function(queue)
  return "queue/" .. (queue or '')
end

Keys.future_queue = function(queue)
  return Keys.queue(queue) .. "/future"
end

Keys.strand = function(strand_name)
  if strand_name and string.len(strand_name) > 0 then
    return "strand/" .. strand_name
  else
    return nil
  end
end

Keys.tag_counts = function(flavor)
  return "tag_counts/" .. flavor
end

Keys.tag = function(tag)
  return "tag/" .. tag
end

Keys.waiting_strand_job_priority = function()
  return 2000000
end

-- remove the given job from the various queues
local remove_from_queues = function(job_id, queue, strand)
  local tag = unpack(redis.call('HMGET', Keys.job(job_id), 'tag'))

  redis.call("SREM", Keys.tag(tag), job_id)

  local current_delta = -redis.call('ZREM', Keys.queue(queue), job_id)
  redis.call('ZREM', Keys.running_jobs(), job_id)
  local future_delta = -redis.call('ZREM', Keys.future_queue(queue), job_id)

  if current_delta ~= 0 then
    redis.call('ZINCRBY', Keys.tag_counts('current'), current_delta, tag)
  end

  local total_delta = current_delta + future_delta

  if total_delta ~= 0 then
    redis.call('ZINCRBY', Keys.tag_counts('all'), total_delta, tag)
  end

  local strand_key = Keys.strand(strand)
  if strand_key then
    redis.call('LREM', strand_key, 1, job_id)
  end
end

-- returns the id for the first job on the strand, or nil if none
local strand_next_job_id = function(strand)
  local strand_key = Keys.strand(strand)
  if not strand_key then return nil end
  return redis.call('LRANGE', strand_key, 0, 0)[1]
end

-- returns next_in_strand -- whether this added job is at the front of the strand
local add_to_strand = function(job_id, strand)
  local strand_key = Keys.strand(strand)
  if not strand_key then return end
  redis.call('RPUSH', strand_key, job_id) -- add to strand list
  local next_id = strand_next_job_id(strand)
  return next_id == job_id
end

-- add this given job to the correct queues based on its state and the current time
-- also updates the tag counts and tag job lists
local add_to_queues = function(job_id, queue, now)
  local run_at, priority, tag, strand = unpack(redis.call('HMGET', Keys.job(job_id), 'run_at', 'priority', 'tag', 'strand'))

  redis.call("SADD", Keys.tag(tag), job_id)

  if strand then
    local next_job_id = strand_next_job_id(strand)
    if next_job_id and next_job_id ~= job_id then
      priority = Keys.waiting_strand_job_priority()
    end
  end

  local current_delta = 0
  local future_delta = 0

  if run_at > now then
    future_delta = future_delta + redis.call('ZADD', Keys.future_queue(queue), run_at, job_id)
    current_delta = current_delta - redis.call('ZREM', Keys.queue(queue), job_id)
  else
    -- floor the run_at so we don't have a float in our float
    local sort_key = priority .. '.' .. math.floor(run_at)
    current_delta = current_delta + redis.call('ZADD', Keys.queue(queue), sort_key, job_id)
    future_delta = future_delta - redis.call('ZREM', Keys.future_queue(queue), job_id)
  end

  if current_delta ~= 0 then
    redis.call('ZINCRBY', Keys.tag_counts('current'), current_delta, tag)
  end

  local total_delta = current_delta + future_delta

  if total_delta ~= 0 then
    redis.call('ZINCRBY', Keys.tag_counts('all'), total_delta, tag)
  end
end

local job_exists = function(job_id)
  return job_id and redis.call('HGET', Keys.job(job_id), 'id')
end

-- find jobs available for running
-- checks the future queue too, and moves and now-ready jobs
-- into the current queue
local find_available = function(queue, limit, offset, min_priority, max_priority, now)
  local ready_future_jobs = redis.call('ZRANGEBYSCORE', Keys.future_queue(queue), 0, now, 'limit', 0, limit)
  for i, job_id in ipairs(ready_future_jobs) do
    add_to_queues(job_id, queue, now)
  end

  if not min_priority or min_priority == '' then
    min_priority = '0'
  end

  if not max_priority or max_priority == '' then
    max_priority = "+inf"
  else
    max_priority = "(" .. (max_priority + 1)
  end
  local job_ids = redis.call('ZRANGEBYSCORE', Keys.queue(queue), min_priority, max_priority, 'limit', offset, limit)
  for idx = table.getn(job_ids), 1, -1 do
    local job_id = job_ids[idx]
    if not job_exists(job_id) then
      table.remove(job_ids, idx)
      redis.call('ZREM', Keys.queue(queue), job_id)
    end
  end
  return job_ids
end

-- "tickle" the strand, removing the given job_id and setting the job at the
-- front of the strand as eligible to run, if it's not already
local tickle_strand = function(job_id, strand, now)
  local strand_key = Keys.strand(strand)

  -- this LREM could be (relatively) slow if the strand is very large and this
  -- job isn't near the front. however, in normal usage, we only delete from the
  -- front. also the linked list is in memory, so even with thousands of jobs on
  -- the strand it'll be quite fast.
  --
  -- alternatively we could make strands sorted sets, which would avoid a
  -- linear search to delete this job. jobs need to be sorted on insertion
  -- order though, and we're using GUIDs for keys here rather than an
  -- incrementing integer, so we'd have to use an artificial counter as the
  -- sort key (through `incrby strand_name` probably).
  redis.call('LREM', strand_key, 1, job_id)
  -- normally this loop will only run once, but we loop so that if there's any
  -- job ids on the strand that don't actually exist anymore, we'll throw them
  -- out and keep searching until we find a legit job or the strand is empty
  while true do
    local next_id = redis.call('LRANGE', strand_key, 0, 0)[1]
    if next_id == nil then
      break
    elseif job_exists(next_id) then
      -- technically jobs on the same strand can be in different queues,
      -- though that functionality isn't currently used
      local queue = redis.call('HGET', Keys.job(next_id), 'queue')
      add_to_queues(next_id, queue, now)
      break
    else
      redis.call('LPOP', strand_key)
    end
  end
end

local destroy_job = function(job_id, now)
  local queue, strand = unpack(redis.call('HMGET', Keys.job(job_id), 'queue', 'strand'))
  remove_from_queues(job_id, queue, strand)

  if Keys.strand(strand) then
    tickle_strand(job_id, strand, now)
  end

  redis.call('ZREM', Keys.failed_jobs(), job_id)
  redis.call('DEL', Keys.job(job_id))
end
