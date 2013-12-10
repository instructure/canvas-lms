define ->
  # This divides a range iteratively, using progressively smaller binary
  # increments. A potential improvement here would be jumping around
  # within each pass, to avoid having a temporarily lopsided distribution,
  # but it's not too bad.
  #
  # I originally implemented this using the golden ratio, which gives nice
  # results for small numbers, but it's significantly worse at scale.

  fairSlicer = (count, min = 0, max = 1, start = 0) ->
    width = max - min

    step = 1
    gapCount = 1
    gapIdx = 0
    pos = 0

    slices = []
    for i in [0...count]
      cut = pos + step
      pos += step * 2

      gapIdx++
      if gapIdx == gapCount
          gapIdx = 0
          pos = 0
          step /= 2
          gapCount = 1 / step / 2

      cut = min + cut*width + start
      cut -= width if cut >= max
      slices.push(cut)
    slices
