local debounce_key = KEYS[1]
local debounce_window = ARGV[1]
local debounce_value = "1"

-- if equal we can do nothing, as we JUST cleared the db
if redis.call("get", debounce_key) ~= debounce_value
then
  redis.call("flushdb")
  redis.call("setex", debounce_key, debounce_window, debounce_value)
end
return redis.call("ttl", debounce_key)

