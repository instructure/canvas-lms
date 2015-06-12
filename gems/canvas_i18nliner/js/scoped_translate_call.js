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
    // TODO: make i18nliner-js use the latter, just like i18nliner(.rb) ...
    // i18nliner-handlebars can't use the former
    if (!this.inferredKey && !this.options.i18n_inferred_key)
      this.key = this.normalizeKey(this.key);
    TranslateCall.prototype.normalize.call(this);
  };

  return ScopedTranslateCall;
}
