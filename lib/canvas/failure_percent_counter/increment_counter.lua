-- This implements a rolling counter in redis using ordered sets
local cache_key = ARGV[1]
local current_time = tonumber(ARGV[2])
local random_value = ARGV[3]
local period = tonumber(ARGV[4])

local cleanup_time = current_time - period

redis.call('ZADD', cache_key, 'NX', current_time, random_value)
redis.call('EXPIRE', cache_key, period)
redis.call('ZREMRANGEBYSCORE', cache_key, 0, cleanup_time)
return redis.call('ZCOUNT', cache_key, cleanup_time, current_time)
