var I18nliner = require("i18nliner");
var Commands = I18nliner.Commands;
var Check = Commands.Check;


var JsProcessor = require("i18nliner/dist/lib/processors/js_processor");
var HbsProcessor = require("i18nliner-handlebars/dist/lib/hbs_processor");
var CallHelpers = require("i18nliner/dist/lib/call_helpers");

var glob = require("glob");

// explict subdirs, to work around perf issues
// https://github.com/jenseng/i18nliner-js/issues/7
JsProcessor.prototype.directories = ["public/javascripts"];
HbsProcessor.prototype.directories = ["app/views/jst", "app/coffeescripts/ember"];
HbsProcessor.prototype.defaultPattern = ["*.hbs", "*.handlebars"];

require("./scoped_hbs_pre_processor");
var ScopedI18nJsExtractor = require("./scoped_i18n_js_extractor");
var ScopedHbsExtractor = require("./scoped_hbs_extractor");
var ScopedTranslationHash = require("./scoped_translation_hash");

// remove path stuff we don't want in the scope
var pathRegex = new RegExp(
  "^(" + HbsProcessor.prototype.directories.join("|") + ")(/plugins/[^/]+)?/"
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
    Commands.run(argv._[0], argv) || process.exit(1);
  }
};
