define ->
  walk = (arr, prop, iterator) ->
    for item in arr
      iterator item, arr
      walk(item[prop], prop, iterator) if item[prop]?
    arr

