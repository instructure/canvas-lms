var HbsExtractor = require("i18nliner-handlebars/dist/lib/extractor").default;

var HbsTranslateCall = require("i18nliner-handlebars/dist/lib/t_call").default;
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
                  .replace("-", "_")
                  .replace(/\/_?/g, '.')
                  .toLowerCase();
  this.scope = scope;
};

ScopedHbsExtractor.prototype.buildTranslateCall = function(sexpr) {
  return new ScopedHbsTranslateCall(sexpr, this.scope);
};

module.exports = ScopedHbsExtractor;
