# Adds _.sum method.
#
# Use like:
#
# _.sum([2,3,4]) #=> 9
#
# or with a custom accessor:
#
# _.sum([[2,3], [3,4]], (a) -> a[0]) #=> 5

define [
  'underscore'
], (_) ->
  _.mixin({
    sum: (array, accessor=null, start=0) ->
      _.reduce(array, (memo, el) ->
        (if accessor? then accessor(el) else el) + memo
      , start)
  })
