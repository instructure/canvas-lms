var I18nliner = require("i18nliner").default;
var Commands = I18nliner.Commands;
var Check = Commands.Check;
var mkdirp = require("mkdirp");
var fs = require("fs");

/*
 * GenerateJs determines what needs to go into each i18n js bundle (one
 * per "i18n!scope"), based on the I18n.t calls in the code
 *
 * outputs a json file containing a mapping of scopes <-> translation keys,
 * e.g.
 *
 * {
 *   "users": [
 *     "users.title",
 *     "users.labels.foo",
 *     "foo_bar_baz" // could be from a different scope, if called within the users scope
 *   ],
 *   "groups:" [
 *     ...
 *   ],
 *   ...
 *
 */

function GenerateJs(options) {
  Check.call(this, options)
}

GenerateJs.prototype = Object.create(Check.prototype);
GenerateJs.prototype.constructor = GenerateJs;

GenerateJs.prototype.run = function() {
  var success = Check.prototype.run.call(this);
  if (!success) return false;
  var keysByScope = this.translations.keysByScope();
  this.outputFile = './' + (this.options.outputFile || "config/locales/generated/js_bundles.json");
  mkdirp.sync(this.outputFile.replace(/\/[^\/]+$/, ''));
  fs.writeFileSync(this.outputFile, JSON.stringify(keysByScope));
  return true;
};

module.exports = GenerateJs;
