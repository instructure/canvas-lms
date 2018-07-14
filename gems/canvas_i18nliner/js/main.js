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
var Commands = I18nliner.Commands;
var Check = Commands.Check;

var CoffeeScript = require("coffee-script");
var babylon = require("babylon");
var fs = require('fs');

var JsProcessor = require("i18nliner/dist/lib/processors/js_processor").default;
var HbsProcessor = require("i18nliner-handlebars/dist/lib/hbs_processor").default;
var CallHelpers = require("i18nliner/dist/lib/call_helpers").default;

var glob = require("glob");

// explict subdirs, to work around perf issues
// https://github.com/jenseng/i18nliner-js/issues/7
JsProcessor.prototype.directories = [
    "public/javascripts",
    "app/coffeescripts",
    "app/jsx"
  ].concat(glob.sync("gems/plugins/*/app/jsx"))
   .concat(glob.sync("gems/plugins/*/app/coffeescripts"))
   .concat(glob.sync("gems/plugins/*/public/javascripts"));
JsProcessor.prototype.defaultPattern = ["*.js", "*.jsx", "*.coffee"];

HbsProcessor.prototype.directories = [
    "app/views/jst",
    "app/coffeescripts/ember"
]  .concat(glob.sync("gems/plugins/*/app/views/jst"))
HbsProcessor.prototype.defaultPattern = ["*.hbs", "*.handlebars"];

JsProcessor.prototype.sourceFor = function(file) {
  var source = fs.readFileSync(file).toString();
  var data = { source: source, skip: !source.match(/I18n\.t/) };

  if (!data.skip) {
    if (file.match(/\.coffee$/)) {
      data.source = CoffeeScript.compile(source, {});
    }
    data.ast = babylon.parse(data.source, { plugins: ["jsx", "classProperties", "objectRestSpread"], sourceType: "module" });
  }
  return data;
};

// we do the actual pre-processing in sourceFor, so just pass data straight through
JsProcessor.prototype.preProcess = function(data) {
  return data;
};

require("./scoped_hbs_pre_processor");
var ScopedI18nJsExtractor = require("./scoped_i18n_js_extractor");
var ScopedHbsExtractor = require("./scoped_hbs_extractor");
var ScopedTranslationHash = require("./scoped_translation_hash");

// remove path stuff we don't want in the scope
var pathRegex = new RegExp(
  ".*(" + HbsProcessor.prototype.directories.join("|") + ")(/plugins/[^/]+)?/" // remove plugins bit once we drop requirejs/handlebars_tasks/plugin symlinks
);
ScopedHbsExtractor.prototype.normalizePath = function(path) {
  return path.replace(pathRegex, "").replace(/^([^\/]+\/)templates\//, '$1');
};

var GenerateJs = require("./generate_js");
Commands.Generate_js = GenerateJs;

// swap out the defaults for our scope-aware varieties
Check.prototype.TranslationHash = ScopedTranslationHash;
JsProcessor.prototype.I18nJsExtractor = ScopedI18nJsExtractor;
HbsProcessor.prototype.Extractor = ScopedHbsExtractor;
CallHelpers.keyPattern = /^\#?\w+(\.\w+)+$/ // handle our absolute keys

module.exports = {
  I18nliner: I18nliner,
  runCommand: function(argv) {
    argv = require('minimist')(argv);
    // the unlink/symlink uglieness is a temporary hack to get around our circular
    // symlinks. we should just remove the symlinks
    fs.unlinkSync('./public/javascripts/symlink_to_node_modules')
    Commands.run(argv._[0], argv) || process.exit(1);
    fs.symlinkSync('../../node_modules', './public/javascripts/symlink_to_node_modules')

  }
};
