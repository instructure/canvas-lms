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
    if (input == null) {
      return NaN
    } else if (typeof input === 'number') {
      return input
    }

    let num = helper._parseNumber(input.toString(), {
      thousands: I18n.lookup('number.format.delimiter'),
      decimal: I18n.lookup('number.format.separator'),
    })

    // fallback to default delimiters if invalid with locale specific ones
    if (Number.isNaN(Number(num))) {
      num = helper._parseNumber(input)
    }

    // final fallback to old parseFloat - this allows us to still support scientific 'e' notation
    if (Number.isNaN(Number(num)) && helper.isScientific(input.toString())) {
      num = parseFloat(input)
    }

    return num
  },

  validate(input: number | string) {
    return !Number.isNaN(Number(helper.parse(input)))
  },

  isScientific(inputString: string) {
    const scientificPattern = /^[+-]?\d+(\.\d*)?([eE][+-]?\d+)$/
    return inputString.match(scientificPattern)
  },
}

export default helper
