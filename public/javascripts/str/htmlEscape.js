/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

define(['INST'], function(INST) {
  function SafeString(string) {
    this.string = (typeof string === 'string' ? string : "" + string);
  }
  SafeString.prototype.toString = function() {
    return this.string;
  };

  var ENTITIES = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#x27;',
    '/': '&#x2F;',
    '`': '&#x60;',  // for old versions of IE
    '=': '&#x3D;'   // in case of unquoted attributes
  };

  var htmlEscape = function(str) {
    // ideally we should wrap this in a SafeString, but this is how it has
    // always worked :-/
    return str.replace(/[&<>"'\/`=]/g, function(c) {
        return ENTITIES[c];
    });
  }

  // Escapes HTML tags from string, or object string props of `strOrObject`.
  // returns the new string, or the object with escaped properties
  var escape = function(strOrObject) {
    if (typeof strOrObject === 'string') {
      return htmlEscape(strOrObject);
    } else if (strOrObject instanceof SafeString) {
      return strOrObject;
    } else if (typeof strOrObject === 'number') {
      return escape(strOrObject.toString())
    }

    var k, v;
    for (k in strOrObject) {
      v = strOrObject[k];
      if (typeof v === "string") {
        strOrObject[k] = htmlEscape(v);
      }
    }
    return strOrObject;
  };
  escape.SafeString = SafeString;

  // tinymce plugins use this and they need it global :(
  INST.htmlEscape = escape;

  return escape;
});

