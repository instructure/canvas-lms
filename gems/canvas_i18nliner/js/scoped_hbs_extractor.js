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

var HbsExtractor = require("@instructure/i18nliner-handlebars/dist/lib/extractor").default;

var HbsTranslateCall = require("@instructure/i18nliner-handlebars/dist/lib/t_call").default;
var ScopedHbsTranslateCall = require("./scoped_translate_call")(HbsTranslateCall);

function ScopedHbsExtractor(ast, options) {
  this.inferI18nScope(options.path);
  HbsExtractor.apply(this, arguments);
};

ScopedHbsExtractor.prototype = Object.create(HbsExtractor.prototype);
ScopedHbsExtractor.prototype.constructor = ScopedHbsExtractor;

ScopedHbsExtractor.prototype.normalizePath = function(path) {
  return path;
};

ScopedHbsExtractor.prototype.inferI18nScope = function(path) {
  if (this.normalizePath)
    path = this.normalizePath(path);
  var scope = path.replace(/\.[^\.]+/, '') // remove extension
                  .replace(/^_/, '')       // some hbs files have a leading _
                  .replace(/([A-Z]+)([A-Z][a-z])/g,'$1_$2') // camel -> underscore
                  .replace(/([a-z\d])([A-Z])/g, '$1_$2')    // ditto
                  .replace(/-/g, "_")
                  .replace(/\/_?/g, '.')
                  .toLowerCase();
  this.scope = scope;
};

ScopedHbsExtractor.prototype.buildTranslateCall = function(sexpr) {
  return new ScopedHbsTranslateCall(sexpr, this.scope);
};

module.exports = ScopedHbsExtractor;
