var Errors = require("i18nliner/dist/lib/errors");
Errors.register("UnscopedTranslateCall");

var TranslateCall = require("i18nliner/dist/lib/extractors/translate_call");
var ScopedTranslateCall = require("./scoped_translate_call")(TranslateCall);

var I18nJsExtractor = require("i18nliner/dist/lib/extractors/i18n_js_extractor");

function ScopedI18nJsExtractor() {
  I18nJsExtractor.apply(this, arguments);
};

ScopedI18nJsExtractor.prototype = Object.create(I18nJsExtractor.prototype);
ScopedI18nJsExtractor.prototype.constructor = ScopedI18nJsExtractor;


ScopedI18nJsExtractor.prototype.processCall = function(node, traverse) {
  this.inferI18nScope(node);
  I18nJsExtractor.prototype.processCall.call(this, node, traverse);
  if (this.i18nScope && this.i18nScope.node === node) {
    this.popI18nScope();
  }
};

ScopedI18nJsExtractor.prototype.inferI18nScope = function(node) {
  var callee = node.callee;
  var method = callee.name;
  var args = node.arguments;

  if (callee.type !== "Identifier")                return;
  if (method !== "require" && method !== "define") return;

  var depsIndex = 0;
  // named define
  if (method === "define" && args[0] && args[0].type === "Literal")
    depsIndex = 1;

  if (!args[depsIndex])                            return;
  if (args[depsIndex].type !== "ArrayExpression")  return;

  var deps = args[depsIndex].elements;
  var depsLen = deps.length;
  var dep;
  for (var i = 0; i < depsLen; i++) {
    dep = deps[i];
    if (dep.type !== "Literal") continue;
    var scope = /^i18n!(.*)$/.exec(dep.value);
    if (scope && (scope = scope[1])) {
      this.pushI18nScope({name: scope, node: node});
    }
  }
};

ScopedI18nJsExtractor.prototype.pushI18nScope = function(scope) {
  var stack = this.i18nScopeStack = this.i18nScopeStack || [];
  stack.push(scope);
  this.i18nScope = scope;
  this.handler
};

ScopedI18nJsExtractor.prototype.popI18nScope = function() {
  var stack = this.i18nScopeStack;
  stack.pop();
  this.i18nScope = stack[stack.length - 1];
};

ScopedI18nJsExtractor.prototype.buildTranslateCall = function(line, method, args) {
  // until we redo how we get translations onto the page, I18n.t calls
  // need to be inside a scope block even if they have inferred keys
  if (!this.i18nScope) { throw new Errors.UnscopedTranslateCall(line) };
  return new ScopedTranslateCall(line, method, args, this.i18nScope.name);
};

module.exports = ScopedI18nJsExtractor;
