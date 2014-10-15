var I18nliner = require("i18nliner")["default"];
var Commands = I18nliner.Commands;
var Check = Commands.Check;
var JsProcessor = require("i18nliner/dist/lib/processors/js_processor")["default"];
var CallHelpers = require("i18nliner/dist/lib/call_helpers")["default"];

var glob = require("glob");


// explict subdirs, to work around perf issues and symlinks:
// https://github.com/jenseng/i18nliner-js/issues/7
// https://github.com/jenseng/globby-js/issues/2
JsProcessor.prototype.directories = ["public/javascripts"].concat(glob.sync("public/javascripts/plugins/*"));

var ScopedI18nJsExtractor = require("./scoped_i18n_js_extractor");
var ScopedTranslationHash = require("./scoped_translation_hash");

var GenerateJs = require("./generate_js");
Commands.Generate_js = GenerateJs;

// swap out the defaults for our scope-aware varieties
Check.prototype.TranslationHash = ScopedTranslationHash;
JsProcessor.prototype.I18nJsExtractor = ScopedI18nJsExtractor;
CallHelpers.keyPattern = /^\#?\w+(\.\w+)+$/ // handle our absolute keys

module.exports = {
  I18nliner: I18nliner,
  runCommand: function(argv) {
    argv = require('minimist')(argv);
    Commands.run(argv._[0], argv) || process.exit(1);
  }
};
