# copy/pasted from: 
# http://matthaynes.net/blog/2008/08/07/javascript-colour-functions/

define ->

  # /** 
  # * Converts HSV to RGB value. 
  # * 
  # * @param {Integer} h Hue as a value between 0 - 360 degrees 
  # * @param {Integer} s Saturation as a value between 0 - 100 % 
  # * @param {Integer} v Value as a value between 0 - 100 % 
  # * @returns {Array} The RGB values  EG: [r,g,b], [255,255,255] 
  # */
  hsvToRgb = (h, s, v) ->
    s = s / 100
    v = v / 100
    hi = Math.floor((h / 60) % 6)
    f = (h / 60) - hi
    p = v * (1 - s)
    q = v * (1 - f * s)
    t = v * (1 - (1 - f) * s)
    rgb = []
    
    switch hi
      when 0
        rgb = [ v, t, p ]
      when 1
        rgb = [ q, v, p ]
      when 2
        rgb = [ p, v, t ]
      when 3
        rgb = [ p, q, v ]
      when 4
        rgb = [ t, p, v ]
      when 5
        rgb = [ v, p, q ]
    
    r = Math.min(255, Math.round(rgb[0] * 256))
    g = Math.min(255, Math.round(rgb[1] * 256))
    b = Math.min(255, Math.round(rgb[2] * 256))
    
    [ r, g, b ]