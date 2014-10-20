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
    } else if (options.bright) {
      l = 74;
    } else if (options.unsafe) {
      l = 60;
    } else {
      l = 49;
    }
    if (options.c) {
      c = options.c;
    } else {
      c = 3 + l / 2;

      // vary chroma to roughly match boundary of darkest RGB-expressible colors
      var delta = 5 + l/4;
      var most_constrained_hue = 210;
      var hr = (h - most_constrained_hue) / 360 * 2 * Math.PI;
      c += Math.floor(delta - delta * Math.cos(hr));

      // constrain chroma by lightest RGB-expressible colors
      var overpower = Math.max(Math.floor(160 - (l * 8 / 5)), 0);
      c = Math.min(c, overpower);
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
