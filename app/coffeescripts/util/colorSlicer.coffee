define [
  'compiled/util/hsvToRgb'
  'compiled/util/fairSlicer'
], (hsvToRgb, fairSlicer) ->
  # This uses fairSlicer to provide arbitrarily fine
  # divisions of the hue space. It adjusts saturation
  # and brightness to try to maintain legibility
  # and visual distinctness.

  # x here is a hue angle in degrees

  # vary from 95 saturation at red and cyan to 75 at green and violet
  hueToSaturation: (x) -> 85 +
    Math.round(Math.cos((x-10) / 90 * Math.PI) * 10)

  # This tries to give vivid reds, oranges, and blues,
  # but deep cyans, greens, yellows, and purples.
  # http://imgur.com/YTwrQR1
  hueToBrightness: (x) -> 75 +
    Math.round(Math.cos((x) / 60 * Math.PI) * 10) +
    Math.round(Math.cos((x-20) / 90 * Math.PI) * 5) +
    Math.round(Math.cos((x-30) / 180 * Math.PI) * 10)

  hueToHSV: (x) ->
    return [x, @hueToSaturation(x), @hueToBrightness(x)]

  hueToCSS: (x) ->
    [h, s, b] = @hueToHSV(x)
    rgbArray = hsvToRgb(h,s,b)
    "rgb(#{rgbArray.join ','})"

  getColors: (limit, startX = 270) ->
    slices = fairSlicer(limit, 0, 360, startX)
    slices.map(@hueToCSS.bind(this))
