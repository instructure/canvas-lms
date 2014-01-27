// This uses fairSlicer to provide arbitrarily fine
// divisions of the hue space. It uses the lab color
// space to maintain legibility and distinctiveness.

// x here is a hue angle in degrees

var fairSlicer = require('./lib/fair-slicer');
var converter = require("color-convert");

module.exports = {
  lchToLab: function(lch) {
    var l = lch[0];
    var c = lch[1];
    var h = lch[2] / 360 * 2 * Math.PI;
    return [l, c * Math.cos(h), c * Math.sin(h)];
  },

  hueToLch: function(options, h) {
    var l, c;
    if (options.l) {
      l = options.l;
      c = options.c;
    } else if (options.bright) {
      l = 73;
      c = 42;
    } else {
      l = 50;
      c = 32;
      // vary chroma to roughly match boundary of RGB-expressible colors
      var delta = 18;
      var most_constrained_hue = 210;
      var hr = (h - most_constrained_hue) / 360 * 2 * Math.PI;
      c += delta - Math.round(delta * Math.cos(hr));
    }
    return [l, c, h]
  },

  lchToCss: function(lch) {
    return this.rgbToCss(this.labToRgb(this.lchToLab(lch)));
  },

  labToRgb: function(lab) {
    var xyz = converter.lab2xyz.apply(converter, lab);
    var rgb = converter.xyz2rgb.apply(converter, xyz);
    return rgb;
  },

  rgbToCss: function(rgb) {
    return "rgb("+rgb.join(',')+")";
  },

  getLchColors: function(limit, startX, options) {
    if (startX === undefined) {
      startX = 330;
    }
    if (!options) {
      options = {};
    }

    var hueToLch = function(h) {
      return this.hueToLch(options, h);
    }.bind(this);

    var slices = fairSlicer(limit, 0, 360, startX);
    return slices.map(hueToLch);
  },

  getLabColors: function(limit, startX, options) {
    var lchColors = this.getLchColors(limit, startX, options);
    return lchColors.map(this.lchToLab);
  },

  getRgbColors: function(limit, startX, options) {
    var labColors = this.getLabColors(limit, startX, options);
    return labColors.map(this.labToRgb);
  },

  getColors: function(limit, startX, options) {
    var rgbColors = this.getRgbColors(limit, startX, options);
    return rgbColors.map(this.rgbToCss);
  }
};
