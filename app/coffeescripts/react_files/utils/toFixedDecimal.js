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

// Converts a number to the given number of decimal places, only when needed.
// You have the option of calling it using either of these two ways:
//
// With Parameters:
//   toFixedDecimal(3.14159, 3) => 3.141
//
// With Object:
//   toFixedDecimal({number: 3.14159, decimals: 2}) => 3.14
export default function toFixedDecimal(number, decimalPlaces) {
  // This is a slightly weak check, but it will suffice for now, just make
  // sure you use a plain object and not an array, etc.
  if (typeof number !== 'number') {
    decimalPlaces = number != null ? number.decimals : undefined
    number = number != null ? number.number : undefined
  }
  return parseFloat(number.toFixed(decimalPlaces))
}
