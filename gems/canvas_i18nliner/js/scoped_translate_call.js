var TranslateCall = require("i18nliner/dist/lib/extractors/translate_call")["default"];

function ScopedTranslateCall(line, method, args, scope) {
  this.scope = scope;

  TranslateCall.call(this, line, method, args);
};

ScopedTranslateCall.prototype = Object.create(TranslateCall.prototype);
ScopedTranslateCall.prototype.constructor = ScopedTranslateCall;

ScopedTranslateCall.prototype.normalizeKey = function(key) {
  if (key[0] === '#')
    return key.slice(1);
  else
    return this.scope + "." + key;
};

ScopedTranslateCall.prototype.normalize = function() {
  if (!this.inferredKey) this.key = this.normalizeKey(this.key);
  TranslateCall.prototype.normalize.call(this);
};

module.exports = ScopedTranslateCall;
