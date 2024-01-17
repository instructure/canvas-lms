/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

// translate a strftime style format string into a datepicker style format string
// Examples:
// %a %b %-d, %Y %-l:%M%P
// %a %b %-d, %Y %-k:%M
// %b %-d, %Y
import {adjustFormat} from './index'

export default function datePickerFormat(format) {
  return adjustFormat(quoteLiteralStrings(format))
    .replace(/%Y/, 'yy') // Year (eg. 2017)
    .replace(/%b/, 'M') // Month (eg. May)
    .replace(/%m/, 'm') // Month (eg. 3)
    .replace(/%-?d/, 'd') // Day of Month (eg. 3)
    .replace(/%a/, 'D') // Day of week (eg. Wed)
    .replace(/%-?[lk]|:|%M|%P/g, '') // Remove time info*
    .trim()
  // *Time info removed because it's already added by the datetime picker
}

function quoteLiteralStrings(format) {
  let ret = ''
  let inLiteral = false
  const open = () => {
    if (!inLiteral) {
      ret += "'"
      inLiteral = true
    }
  }
  const close = () => {
    if (inLiteral) {
      ret += "'"
      inLiteral = false
    }
  }
  for (let i = 0; i < format.length; ++i) {
    if (format[i] === ' ') {
      close()
      ret += ' '
    } else if (format[i] === '%' && format[i + 1] === '-' && format[i + 2] != null) {
      close()
      ret += `%-${format[i + 2]}`
      i += 2
    } else if (format[i] === '%' && format[i + 1] != null) {
      close()
      ret += `%${format[i + 1]}`
      i += 1
    } else {
      open()
      ret += format[i]
    }
  }
  close()
  return ret
}
