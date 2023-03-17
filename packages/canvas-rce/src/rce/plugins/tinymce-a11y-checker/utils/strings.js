/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

export function filename(url) {
  const pattern = /([^\/]*?)(\?.*)?$/
  const result = pattern.exec(url)
  return result && result[1]
}

export function firstWords(text, num) {
  const pattern = /\w+/g
  const words = []
  let result
  while (num > 0 && (result = pattern.exec(text))) {
    --num
    words.push(result[0])
  }
  let ret = words.join(' ')
  if (result != null && pattern.exec(text)) {
    ret += '…'
  }
  return ret
}
