define ->
  walk = (arr, prop, iterator) ->
    for item in arr
      result = iterator item, arr
      return true if result?.stop
      return true if walk(item[prop], prop, iterator) if item[prop]?
    return
