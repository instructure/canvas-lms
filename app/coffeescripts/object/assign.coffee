define ->
  ToObject = (val) ->
    if val == null
      throw new TypeError('Object.assign cannot be called with null or undefined')
    Object val

  'use strict'
  ObjectAssign = Object.assign or (target, source) ->
    from = undefined
    keys = undefined
    to = ToObject(target)
    s = 1
    while s < arguments.length
      from = arguments[s]
      keys = Object.keys(Object(from))
      i = 0
      while i < keys.length
        to[keys[i]] = from[keys[i]]
        i++
      s++
    to
