var TranslationHash = require("i18nliner/dist/lib/extractors/translation_hash");

function keys(obj) {
  var result = [];
  for (var key in obj) {
    if (obj.hasOwnProperty(key)) result.push(key);
  }
  return result;
}

/* Flatten a deeply nested object, joining intermediate keys with "."
 *
 * e.g.
 *
 * flatten({a: 1, b: {c: 2, d: {e: 3}}})
 * => {"a": 1", "b.c": 2, "b.d.e": 3}
 */
function flatten(obj, prefix, result) {
  result = result || {};
  var subPrefix;
  var value;
  for (var key in obj) {
    if (obj.hasOwnProperty(key)) {
      var value = obj[key];
      fullKey = prefix ? prefix + "." + key : key;
      if (value instanceof Object && !(value instanceof Array)) {
        flatten(value, fullKey, result);
      } else {
        result[fullKey] = value;
      }
    }
  }
  return result;
}


/* Track a different TranslationHash for each scope.
 *
 * This is needed for i18n:generate_js, since it builds a separate
 * translation bundle for each i18n scope (so the "i18n!scope" magic
 * works)
 */

function ScopedTranslationHash() {
  this.hashes = {};
  this.masterHash = new TranslationHash()
  this.translations = this.masterHash.translations;
}

ScopedTranslationHash.prototype.set = function(key, value, meta) {
  this.masterHash.set(key, value, meta); // we need this for collision checking
  var scope = meta.scope;
  var hash = this.hashes[scope] = this.hashes[scope] || new TranslationHash();
  hash.set(key, value, meta);
};

ScopedTranslationHash.prototype.keysByScope = function() {
  var hash = {};
  for (key in this.hashes) {
    hash[key] = keys(flatten(this.hashes[key].translations));
  }
  return hash;
};

module.exports = ScopedTranslationHash;
