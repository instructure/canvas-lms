local fallback_register_key = ARGV[1]

local frd_key = KEYS[1]
local missing_timestamp = false
for i, register_key in ipairs(KEYS) do
  if i > 1 then
    local fetched_key = redis.call("get", register_key)
    if fetched_key then
      frd_key = frd_key .. "/" .. fetched_key
    else
      -- if it's not there, then set it
      missing_timestamp = true
      redis.call("set", register_key, fallback_register_key)
      frd_key = frd_key .. "/" .. fallback_register_key
    end
  end
end

if missing_timestamp then
    return {frd_key, nil}
else
    return {frd_key, redis.call("get", frd_key)}
end
