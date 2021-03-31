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
var path = require('path')
var fs = require('fs')

function ScopedHbsExtractor(ast, options) {
  // read the scope from the i18nScope property in the accompanying .json file:
  this.scope = ScopedHbsExtractor.readI18nScopeFromJSONFile(
    // resolve relative to process.cwd() in case it's not absolute
    path.resolve(options.path)
  )

  this.path = options.path // need this for error reporting

  HbsExtractor.apply(this, arguments);
};

ScopedHbsExtractor.prototype = Object.create(HbsExtractor.prototype);
ScopedHbsExtractor.prototype.constructor = ScopedHbsExtractor;

ScopedHbsExtractor.prototype.normalizePath = function(path) {
  return path;
};

ScopedHbsExtractor.prototype.buildTranslateCall = function(sexpr) {
  if (!this.scope) {
    const friendlyFile = path.relative(process.cwd(), this.path)

    throw new Error(`
canvas_i18nliner: expected i18nScope for Handlebars template to be specified in
the accompanying .json file, but found none:

    ${friendlyFile}

To fix this, create the following JSON file with the "i18nScope" property set to
the i18n scope to use for the template (e.g. similar to what you'd do in
JavaScript, like \`import I18n from "i18n!foo.bar"\`):
                                         ^^^^^^^

    // file: ${friendlyFile + '.json'}
    {
      "i18nScope": "..."
    }
`)
  }

  return new ScopedHbsTranslateCall(sexpr, this.scope);
};

ScopedHbsExtractor.readI18nScopeFromJSONFile = function(filepath) {
  const metadataFilepath = `${filepath}.json`

  if (fs.existsSync(metadataFilepath)) {
    return require(metadataFilepath).i18nScope
  }
};

module.exports = ScopedHbsExtractor;