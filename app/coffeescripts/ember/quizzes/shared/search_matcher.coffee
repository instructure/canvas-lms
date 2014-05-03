define [], () ->
  # matches a key against a string
  # returns true if target is a blank string
  (target, key, ignoreCase=true) ->
    return true unless target
    if !!ignoreCase
      target = target.toLowerCase()
      key = key.toLowerCase()
    numMatches = 0
    keys = key.split(' ')
    for sl in keys
      #not using match to avoid javascript string to regex oddness
      numMatches++ if target.indexOf(sl) != -1
    numMatches == keys.length
