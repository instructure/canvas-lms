-- This assumes the ordered sets are being used as a rolling counter
-- and then does math on the size of the two sets
local count_key = KEYS[1]
-- Because we have a distributed redis ring, we'll have issues if both
-- keys are in the key field, so we'll use count, which should always
-- be bigger as the main key, and pass the fail_key as our first
-- argument.
local fail_key = ARGV[1]
local current_time = tonumber(ARGV[2])
local period = tonumber(ARGV[3])
local min_samples = tonumber(ARGV[4])

local cleanup_time = current_time - period

redis.call('ZREMRANGEBYSCORE', count_key, 0, cleanup_time)
local count = redis.call('ZCOUNT', count_key, cleanup_time, current_time)

if count < min_samples then
   return '0.0'
end

redis.call('ZREMRANGEBYSCORE', fail_key, 0, cleanup_time)
local failures = redis.call('ZCOUNT', fail_key, cleanup_time, current_time)

-- redis converts lua numbers to ints, so we have to return a float as a string
return tostring(failures / count)
