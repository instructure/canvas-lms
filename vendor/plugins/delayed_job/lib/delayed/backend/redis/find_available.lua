local queue, limit, offset, min_priority, max_priority, now = unpack(ARGV)

return find_available(queue, limit, offset, min_priority, max_priority, now)
