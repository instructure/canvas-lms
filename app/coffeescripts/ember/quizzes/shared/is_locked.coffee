define [], () ->

  isLocked = (unlockAt, lockAt) ->
    now = new Date()
    locked = false
    if !!lockAt
      if !!unlockAt
        locked = unlockAt > now || lockAt < now
      else
        locked = lockAt < now
    else
      if !!unlockAt
        locked = unlockAt > now
    locked

