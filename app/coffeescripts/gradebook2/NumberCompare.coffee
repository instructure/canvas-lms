define [
  'underscore'
], (_) ->
  (a, b, sortAsc) ->
    val = if !_.isNumber(a)
      if !_.isNumber(b) then 0 else 1
    else if !_.isNumber(b)
      -1
    else
      if sortAsc then a - b else b - a
