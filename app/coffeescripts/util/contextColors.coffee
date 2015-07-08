define [
  'jquery'
  'compiled/util/hsvToRgb'
  'vendor/murmurhash'
], ($, hsvToRgb, murmurhash) ->

  seed = 1
  [bgSaturation, bgBrightness]         = [30, 96]
  [textSaturation, textBrightness]     = [60, 40]
  [strokeSaturation, strokeBrightness] = [70, 70]

  codeToHue: (code) ->
    murmurhash(code, seed) % 360

  hueToRGBs: (hue) ->
    text:       hsvToRgb hue, textSaturation,   textBrightness
    stroke:     hsvToRgb hue, strokeSaturation, strokeBrightness
    background: hsvToRgb hue, bgSaturation,     bgBrightness

  codeToRGBs: (code) ->
    @hueToRGBs @codeToHue code

  injectStyleSheet: (codes) ->
    css = for code, index in codes
      {text, background, stroke} = @codeToRGBs code
      """
        .contextCode-#{code} {
          color: rgb(#{text.join(' ,')});
          background-color: rgb(#{background.join(' ,')});
          border-color: rgb(#{stroke.join(' ,')});
        }

      """
    $('<div/>').html("<style>#{$.raw(css.join(''))}</style>").appendTo(document.body)

