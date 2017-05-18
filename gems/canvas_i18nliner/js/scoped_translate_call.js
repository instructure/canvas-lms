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
