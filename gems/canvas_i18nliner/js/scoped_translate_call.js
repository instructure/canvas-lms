module.exports = function(TranslateCall) {
  var ScopedTranslateCall = function() {
    var args = [].slice.call(arguments);
    this.scope = args.pop();

    TranslateCall.apply(this, arguments);
  }

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

  return ScopedTranslateCall;
}
