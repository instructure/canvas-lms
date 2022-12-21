/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

export default function round(number, decimalDigits = 2) {
  if (decimalDigits < 0) throw new Error('decimal digits must be >= 0')
  if (decimalDigits % 1 !== 0) throw new Error('decimal digits must be a whole number')
  const val = Math.round(number * 10 ** decimalDigits) / 10 ** decimalDigits
  if (Number.isNaN(val)) throw new Error('the first arguments must be a number')
  return val === 0 ? 0 : val // prevent round(-0) from returning -0
}
