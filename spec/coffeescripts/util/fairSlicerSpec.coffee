define [
  'underscore'
  'compiled/util/fairSlicer'
], (_, fairSlicer) ->

  module 'fairSlicer'

  test 'count', ->
    equal fairSlicer(3).length, 3

  test 'range', ->
    slices = fairSlicer(100, -5, 5)
    min = Math.min.apply(null, slices)
    max = Math.max.apply(null, slices)
    ok -5 <= min < -4
    ok 4 < max <= 5

  test 'start', ->
    equal fairSlicer(5, 0, 1, 0.5)[0], 0.5

  test 'spacing', ->
    for limit in [3, 4, 5, 10, 30, 100, 300]
      slices = fairSlicer(limit)
      slices.sort((a, b) -> a - b)
      gaps = _.map _.zip(_.rest(slices), _.initial(slices)), (x) -> x[0] - x[1]
      min = Math.min.apply(null, gaps)
      max = Math.max.apply(null, gaps)
      ok max/min <= 2
      continue
