/*
 * Copyright (C) 2014 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

var I18nliner = require("i18nliner").default;
var TranslateCall = require("i18nliner/dist/lib/extractors/translate_call").default;
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
  var translationsWas = TranslateCall.prototype.translations
  TranslateCall.prototype.translations = function() {
    var key = this.key;
    var defaultValue = this.defaultValue;
  
    if (typeof defaultValue === 'string' || !defaultValue)
      return [[key, defaultValue]];
  
    var translations = [];
    for (var k in defaultValue) {
      if (defaultValue.hasOwnProperty(k)) {
        translations.push([key + "." + k, defaultValue[k]]);
      }
    }
    return translations;
  };
  var success = Check.prototype.run.call(this);
  if (!success) return false;
  var keysByScope = this.translations.keysByScope();
  this.outputFile = './' + (this.options.outputFile || "config/locales/generated/js_bundles.json");
  mkdirp.sync(this.outputFile.replace(/\/[^\/]+$/, ''));
  fs.writeFileSync(this.outputFile, JSON.stringify(keysByScope));
  TranslateCall.prototype.translations = translationsWas
  return true;
};

module.exports = GenerateJs;
