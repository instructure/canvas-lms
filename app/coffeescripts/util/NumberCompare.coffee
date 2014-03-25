define [
  'underscore'
], (_) ->
  (a, b, options = {}) ->
    val = if !_.isNumber(a)
      if !_.isNumber(b) then 0 else 1
    else if !_.isNumber(b)
      -1
    else
      if options.descending then b - a else a - b
