var jQuery = require("jquery");
// this gets the full handlebars.js file, instead of just handlebars.runtime that we alias 'handlebars' to in baseWebpackConfig.js
var Handlebars = require("handlebars/dist/cjs/handlebars").default;

window.Ember = {
  imports: {
    Handlebars: Handlebars,
    jQuery: jQuery
  }
};

window.Handlebars = Handlebars;

var Ember = require("exports-loader?Ember!bower/ember/ember");

module.exports = Ember;
