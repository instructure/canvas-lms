local register_key = KEYS[1]
local fallback_cache_key = ARGV[1]

-- try to grab it
local fetched_key = redis.call("get", register_key)

if fetched_key then
  return fetched_key
else
  -- if it's not there, then set it
  redis.call("set", register_key, fallback_cache_key)
  return fallback_cache_key
end
