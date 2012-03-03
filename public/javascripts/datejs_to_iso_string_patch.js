/**
 * Copyright (C) 2011 Instructure, Inc.
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
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

// the purpose of this file is to define a Date.prototype.toISOString method that doesn't return 
// things like ""2011-02-16T19:00:00Z"" but rather "2011-02-16T19:00:00Z"
// date.js thought it was just using json.org's implementation but was actually adding extra quotes.
// by defineing it here date.js will use it and not define it itself.  for any good browser (not IE) 
// it will use the native toISOString method supplied by the browser.
// 
// this file is the same as http://code.google.com/p/datejs/source/browse/trunk/src/core.js but with 
// the beginning and ending quotes on the return string removed

define(function () {

if (!Date.prototype.toISOString) {
  /**
  * Converts the current date instance into a string with an ISO 8601 format. The date is converted to it's UTC value.
  * @return {String}  ISO 8601 string of date
  */
  Date.prototype.toISOString = function () {
  // From http://www.json.org/json.js. Public Domain. 
  function f(n) {
    return n < 10 ? '0' + n : n;
  }

  return '' + this.getUTCFullYear()   + '-' +
            f(this.getUTCMonth() + 1) + '-' +
            f(this.getUTCDate())      + 'T' +
            f(this.getUTCHours())     + ':' +
            f(this.getUTCMinutes())   + ':' +
            f(this.getUTCSeconds())   + 'Z';
  };
}
});
