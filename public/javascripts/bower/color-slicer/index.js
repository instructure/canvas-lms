// This uses fairSlicer to provide arbitrarily fine
// divisions of the hue space. It uses the lab color
// space to maintain legibility and distinctiveness.

// x here is a hue angle in degrees

var fairSlicer = require('./lib/fair-slicer');
var converter = require("color-convert");

module.exports = {
  hueToRgb: function(h) {
    h = h / 360 * 2 * Math.PI;
    // legible lightness for small text on a white background
    var l = 40;
    // chroma
    var c = 80;
    var lab = [l, c * Math.cos(h), c * Math.sin(h)];
    var xyz = converter.lab2xyz.apply(converter, lab);
    var rgb = converter.xyz2rgb.apply(converter, xyz);
    return rgb;
  },

  rgbToCss: function(rgb) {
    return "rgb("+rgb.join(',')+")";
  },

  getRawColors: function(limit, startX) {
    if (startX === undefined) {
      startX = 330;
    }
    var slices = fairSlicer(limit, 0, 360, startX);
    return slices.map(this.hueToRgb.bind(this));
  },

  getColors: function(limit, startX) {
    var rawColors = this.getRawColors(limit, startX);
    return rawColors.map(this.rgbToCss);
  }
};
