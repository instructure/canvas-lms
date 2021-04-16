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
var babylon = require("@babel/parser");
var fs = require('fs');

var AbstractProcessor = require("i18nliner/dist/lib/processors/abstract_processor").default;
var JsProcessor = require("i18nliner/dist/lib/processors/js_processor").default;
var HbsProcessor = require("@instructure/i18nliner-handlebars/dist/lib/hbs_processor").default;
var CallHelpers = require("i18nliner/dist/lib/call_helpers").default;

var scanner = require("./scanner");

// tell i18nliner's babylon how to handle `import('../foo').then`
I18nliner.config.babylonPlugins.push('dynamicImport')
I18nliner.config.babylonPlugins.push('optionalChaining')

AbstractProcessor.prototype.checkFiles = function() {
  const processor = this.constructor.name.replace(/Processor/, '').toLowerCase()
  const files = scanner.getFilesForProcessor(processor)

  for (const file of files) {
    this.checkWrapper(file, this.checkFile.bind(this))
  }
}

JsProcessor.prototype.sourceFor = function(file) {
  var source = fs.readFileSync(file).toString();
  var data = { source: source, skip: !source.match(/I18n\.t/) };

  if (!data.skip) {
    if (file.match(/\.coffee$/)) {
      data.source = CoffeeScript.compile(source, {});
    }
    data.ast = babylon.parse(data.source, { plugins: I18nliner.config.babylonPlugins, sourceType: "module" });
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
  '.*(' +
    'ui/shared/jst' +
    '|ui/features/screenreader_gradebook/jst' +
    '|packages/[^/]+/src/jst' +
    '|gems/plugins/[^/]+/app/views/jst' +
  ')' +
  '(/plugins/[^/]+)?/' // remove plugins bit once we drop requirejs/handlebars_tasks/plugin symlinks
)

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
  I18nliner,
  runCommand: function(argv) {
    argv = require('minimist')(argv);

    scanner.scanFilesFromI18nrc(
      scanner.loadConfigFromDirectory(
        require('path').resolve(__dirname, '../../..')
      )
    )

    Commands.run(argv._[0], argv) || (process.exitCode = 1);
  }
};
