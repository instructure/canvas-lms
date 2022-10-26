//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

const formatter = {
  0: 'toUpperCase',
  1: 'toLowerCase',
}

// see also lib/i18n/lolcalize.rb
function letThereBeLols(str) {
  // don't want to mangle placeholders, wrappers, etc.
  const pattern = /(\s*%h?\{[^\}]+\}\s*|\s*[\n\\`\*_\{\}\[\]\(\)\#\+\-!]+\s*|^\s+)/

  const result = str.split(pattern).map(token => {
    if (token.match(pattern)) return token
    let s = ''
    // same as for i in [0...token.length] in coffeescript
    for (let i = 0, end = token.length, asc = end >= 0; asc ? i < end : i > end; asc ? i++ : i--) {
      s += token[i][formatter[i % 2]]()
    }
    s = s.replace(/\.( |$)/, '!!?! ')
    s = s.replace(/^(\w+)$/, '$1!')
    if (s.length > 2) s += ' LOL!'
    return s
  })
  return result.join('')
}

export default function i18nLolcalize(strOrObj) {
  if (typeof strOrObj === 'string') return letThereBeLols(strOrObj)

  const result = {}
  for (const key in strOrObj) {
    const value = strOrObj[key]
    result[key] = letThereBeLols(value)
  }
  return result
}
