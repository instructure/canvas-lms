local members = redis.call( 'zrange', 'timings', '0', '-1', 'withscores' )
local ret = {}

for n = 1, #members, 2 do
  local specKey = members[n]

  if string.match(specKey, '^[^:]+$') then
    ret[specKey] = tonumber(members[n + 1])
  end
end

return cjson.encode(ret)
