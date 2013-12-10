define [
  'jquery'
  'compiled/util/colorSlicer'
], ($, colorSlicer) ->

  module 'colorSlicer'

  test 'hueToSaturation', ->
    ok colorSlicer.hueToSaturation(0) > 90
    ok colorSlicer.hueToSaturation(30) > 90
    ok colorSlicer.hueToSaturation(270) < 80

  test 'hueToBrightness', ->
    ok colorSlicer.hueToBrightness(0) > 90
    ok colorSlicer.hueToBrightness(30) > 80
    ok colorSlicer.hueToBrightness(60) < 80
    ok colorSlicer.hueToBrightness(120) > 70
    ok colorSlicer.hueToBrightness(180) < 65
    ok colorSlicer.hueToBrightness(210) > 65
    ok colorSlicer.hueToBrightness(270) < 70
