var I18nliner = require("i18nliner")["default"];
var Commands = I18nliner.Commands;
var Check = Commands.Check;

// it auto-registers its processor
var I18nlinerHbs = require("i18nliner-handlebars");

var JsProcessor = require("i18nliner/dist/lib/processors/js_processor")["default"];
var HbsProcessor = require("i18nliner-handlebars/dist/lib/hbs_processor")["default"];
var CallHelpers = require("i18nliner/dist/lib/call_helpers")["default"];

var glob = require("glob");

// explict subdirs, to work around perf issues
// https://github.com/jenseng/i18nliner-js/issues/7
JsProcessor.prototype.directories = ["public/javascripts"];
HbsProcessor.prototype.directories = ["app/views/jst"];
HbsProcessor.prototype.defaultPattern = "**/*.handlebars";

require("./scoped_hbs_pre_processor");
var ScopedI18nJsExtractor = require("./scoped_i18n_js_extractor");
var ScopedHbsExtractor = require("./scoped_hbs_extractor");
var ScopedTranslationHash = require("./scoped_translation_hash");

// remove path stuff we don't want in the scope
var pathRegex = new RegExp(
  "^" + HbsProcessor.prototype.directories[0] + "(/plugins/[^/]+)?/"
);
ScopedHbsExtractor.prototype.normalizePath = function(path) {
  return path.replace(pathRegex, "");
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
    Commands.run(argv._[0], argv) || process.exit(1);
  }
};
