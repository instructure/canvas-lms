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

define([], function() {
  /**
   * @member Util
   * @method round
   *
   * Round a number to N digits.
   *
   * TODO: import as a Canvas package (we have it in util/round.coffee)
   *
   * @param  {Number|String} n
   *         Your number
   *
   * @param  {Number} [digits=2]
   *         Number of digits to round to.
   *
   * @return {Number}
   *         The rounded number, ready for human-consumption.
   */
  return function round(n, digits) {
    var scale

    if (digits === undefined) {
      digits = 0
    }

    if (typeof n !== 'number' || !(n instanceof Number)) {
      n = parseFloat(n)
    }

    scale = Math.pow(10, parseInt(digits, 10))
    n = Math.round(n * scale) / scale

    return n
  }
})
