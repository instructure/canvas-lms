-- KEYS[1] = Redis list key containing spec paths to time
-- KEYS[2] = sorted set of timing data (member = path, score = seconds)
-- Uses a single ZRANGE to fetch all timings, then filters in Lua.
-- Deterministic: ZRANGE is always allowed in Redis Lua scripts (no ZSCAN).
-- Exact paths use O(1) hash lookup; glob patterns use string.match.
-- A 'seen' table deduplicates keys across overlapping patterns.
-- Returns JSON: { total_time, found_keys, found_entries, missing }

local specListKey = KEYS[1]
local specs = redis.call('LRANGE', specListKey, '0', '-1')
local total = 0
local found_keys = 0
local missing = {}
local seen = {}

-- Separate exact paths from glob patterns
local exactPaths = {}  -- ['./path/to_spec.rb'] = matched (bool)
local globs = {}       -- { orig, pat, matched }

for _, spec in ipairs(specs) do
  if string.match(spec, '%*') then
    -- Escape all Lua pattern magic chars, then convert * to .-
    local pat = spec:gsub('([%(%)%.%%%+%-%?%[%^%$])', '%%%1')
    pat = pat:gsub('%*', '.-')
    table.insert(globs, {orig=spec, pat='^%./'..pat..'$', matched=false})
  else
    exactPaths['./'..spec] = false
  end
end

-- Single ZRANGE pass through all timings
local items = redis.call('ZRANGE', KEYS[2], '0', '-1', 'WITHSCORES')

for i = 1, #items, 2 do
  local key = items[i]
  local score = tonumber(items[i + 1])

  -- Exact path check (O(1) hash lookup)
  if exactPaths[key] ~= nil then
    exactPaths[key] = true  -- mark as matched
    if not seen[key] then
      seen[key] = true
      total = total + score
      found_keys = found_keys + 1
    end
  end

  -- Glob checks: mark all matching globs, count key only once
  for _, g in ipairs(globs) do
    if string.match(key, g.pat) then
      g.matched = true
      if not seen[key] then
        seen[key] = true
        total = total + score
        found_keys = found_keys + 1
      end
    end
  end
end

local foundEntries = 0
for key, matched in pairs(exactPaths) do
  if matched then
    foundEntries = foundEntries + 1
  else
    table.insert(missing, key:sub(3))
  end
end
for _, g in ipairs(globs) do
  if g.matched then
    foundEntries = foundEntries + 1
  else
    table.insert(missing, g.orig)
  end
end

return cjson.encode({total_time=total, found_keys=found_keys, found_entries=foundEntries, missing=missing})
