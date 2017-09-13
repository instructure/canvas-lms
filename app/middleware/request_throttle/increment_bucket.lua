local cache_key = KEYS[1]
local amount = tonumber(ARGV[1])
local current_time = tonumber(ARGV[2])
local outflow = tonumber(ARGV[3])
local maximum = tonumber(ARGV[4])

-- Our modified leaky bucket algorithm is explained in app/middleware/request_throttle.rb
local leak = function(count, last_touched, current_time, outflow)
  if count > 0 then
    local timespan = current_time - last_touched
    local loss = outflow * timespan
    if loss > 0 then
      count = count - loss
    end
  end
  return count, last_touched
end

local count, last_touched = unpack(redis.call('HMGET', cache_key, 'count', 'last_touched'))
count = tonumber(count or 0)
last_touched = tonumber(last_touched or current_time)

count, last_touched = leak(count, last_touched, current_time, outflow)
if count < 0 then count = 0 end

count = count + amount
if count < 0 then count = 0 end
if count > maximum then count = maximum end

redis.call('HMSET', cache_key, 'count', count, 'last_touched', current_time)
-- reset expiration to 1 hour from now each time we write
redis.call('EXPIRE', cache_key, 3600)

-- redis converts lua numbers to ints, so we have to return these as strings
return { tostring(count), tostring(current_time) }
