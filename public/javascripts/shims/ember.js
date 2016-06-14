var jQuery = require("jquery");
var Handlebars = require("exports?Handlebars!bower/handlebars/handlebars");

window.Ember = {
  imports: {
    Handlebars: Handlebars,
    jQuery: jQuery
  }
};

window.Handlebars = Handlebars;

var Ember = require("exports?Ember!bower/ember/ember");

module.exports = Ember;
