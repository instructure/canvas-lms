local action, id_string, flavor, query, now = unpack(ARGV)

local ids = {}

if string.len(flavor) > 0 then
  if flavor == 'current' then
    ids = redis.call('ZRANGE', Keys.queue(query), 0, -1)
  elseif flavor == 'future' then
    ids = redis.call('ZRANGE', Keys.future_queue(query), 0, -1)
  elseif flavor == 'strand' then
    ids = redis.call('LRANGE', Keys.strand(query), 0, -1)
  elseif flavor == 'tag' then
    ids = redis.call('SMEMBERS', Keys.tag(query))
  end
else
  -- can't pass an array to redis/lua, so we split the string here
  for id in string.gmatch(id_string, "([%w-]+)") do
    if job_exists(id) then
      table.insert(ids, id)
    end
  end
end

for idx, job_id in ipairs(ids) do
  if action == 'hold' then
    local queue, strand = unpack(redis.call('HMGET', Keys.job(job_id), 'queue', 'strand'))
    remove_from_queues(job_id, queue, strand)
    redis.call('HMSET', Keys.job(job_id), 'locked_at', now, 'locked_by', 'on hold', 'attempts', 50)
  elseif action == 'unhold' then
    local queue, locked_by = unpack(redis.call('HMGET', Keys.job(job_id), 'queue', 'locked_by'))
    add_to_queues(job_id, queue, now)
    redis.call('HDEL', Keys.job(job_id), 'locked_at', 'locked_by')
    redis.call('HMSET', Keys.job(job_id), 'attempts', 0)
  elseif action == 'destroy' then
    destroy_job(job_id, now)
  end
end

-- returns the # of jobs matching the query, not necessarily the # whose state was changed
return table.getn(ids)
