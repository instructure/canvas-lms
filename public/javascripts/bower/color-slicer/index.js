// This uses fairSlicer to provide arbitrarily fine
// divisions of the hue space. It uses the lab color
// space to maintain legibility and distinctiveness.

// x here is a hue angle in degrees

var fairSlicer = require('./lib/fair-slicer');
var converter = require("color-convert");

module.exports = {
  hueToLch: function(options, h) {
    h = Math.round(h);
    var l, c;
    if (options.l) {
      l = options.l;
      c = options.c;
    } else if (options.bright) {
      l = 74;
      c = 41;
    } else {
      l = 49;
      c = 29;

      // vary chroma to roughly match boundary of RGB-expressible colors
      var delta = 17;
      var most_constrained_hue = 210;
      var hr = (h - most_constrained_hue) / 360 * 2 * Math.PI;
      c += delta - Math.round(delta * Math.cos(hr));
    }
    return [l, c, h]
  },

  lchToRgb: function(lch) {
    return converter.lch2rgb.apply(converter, lch);
  },

  lchToCss: function(lch) {
    return "rgb("+this.lchToRgb(lch).join(',')+")";
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

  getRgbColors: function(limit, startX, options) {
    var lchColors = this.getLchColors(limit, startX, options);
    return lchColors.map(this.lchToRgb);
  },

  getColors: function(limit, startX, options) {
    var lchColors = this.getLchColors(limit, startX, options);
    return lchColors.map(this.lchToCss.bind(this));
  }
};
