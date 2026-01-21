/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import parseNumber from 'parse-decimal-number'
import I18n from './i18nObj'

const helper = {
  _parseNumber: parseNumber,

  parse(input: number | string) {
    if (input == null || input === '') return NaN
    if (typeof input === 'number') return input
    const inputStr = input.toString().trim()
    const separator = I18n.lookup('number.format.separator') || '.'
    const delimiter = I18n.lookup('number.format.delimiter') || ','

    if (helper.isScientific(inputStr)) {
      const normalized = inputStr.replace(separator, '.')
      const scientificNum = parseFloat(normalized)
      if (!Number.isNaN(scientificNum)) {
        return scientificNum
      }
    }

    const num = helper._parseNumber(inputStr, {
      thousands: delimiter,
      decimal: separator,
    })

    return Number.isNaN(Number(num)) ? NaN : num
  },

  validate(input: number | string) {
    return !Number.isNaN(Number(helper.parse(input)))
  },

  isScientific(inputString: string) {
    const separator = I18n.lookup('number.format.separator') || '.'
    const escapedSeparator = separator === '.' ? '\\.' : separator

    // This pattern ensures the [eE] is present to be considered scientific
    // and uses the specific locale separator.
    const pattern = new RegExp(`^[+-]?\\d+(${escapedSeparator}\\d*)?[eE][+-]?\\d+$`)

    return !!inputString.match(pattern)
  },
}

export default helper
