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

// parse the list of names entered by our user into an array
// separates entries on , or \n
// deals with entries like '"Last, First" email' where there's a common w/in quotes
export function parseNameList(nameList) {
  const names = []
  let iStart = 0
  let inQuote = false
  for (let i = 0; i < nameList.length; ++i) {
    const c = nameList.charAt(i)
    if (c === '"') {
      inQuote = !inQuote
    } else if ((c === ',' && !inQuote) || c === '\n') {
      const n = nameList.slice(iStart, i).trim()
      if (n.length) names.push(n)
      iStart = i + 1
    }
  }
  const n = nameList.slice(iStart).trim()
  if (n.length) names.push(n)
  return names
}

export function findEmailInEntry(entry) {
  const tokens = entry.split(/\s+/)
  const emailIndex = tokens.findIndex(t => t.indexOf('@') >= 0)
  return tokens[emailIndex]
}

export const emailValidator = /.+@.+\..+/
