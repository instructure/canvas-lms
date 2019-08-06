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

define([ '../config' ], function(config) {
  var I18n = require('i18n!quiz_statistics').default;
  var parseNumber = require('./parse_number');
  /**
   * @member Util
   * @method formatNumber
   *
   * Format a decimal number into a human-readable string.
   * Examples:
   *
   *     83.2222224 => "83.22"
   *     25 => "25.00"
   *     24.94 => "24.94"
   *
   * @param  {Number|String} n
   *         Your number
   *
   * @param  {Number} [precision=config.precision]
   *         Precision of the returned float (number of digits after the
   *         decimal point.)
   *
   * @return {String}
   *         The formatted number, ready for rendering.
   */
  return function formatNumber(n, precision) {
    if (precision === undefined) {
      precision = config.precision;
    }

    if (typeof n !== 'number' || !(n instanceof Number)) {
      n = parseNumber(n);
    }

    return I18n.n(n.toFixed(parseInt(precision, 10)));
  };
});
