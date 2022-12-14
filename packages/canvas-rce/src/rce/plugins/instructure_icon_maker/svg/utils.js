/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

export function createSvgElement(tag, attributes = {}) {
  const element = document.createElementNS('http://www.w3.org/2000/svg', tag)
  Object.entries(attributes).forEach(([attr, value]) => {
    element.setAttribute(attr, value)
  })
  return element
}

export function splitTextIntoLines(text, maxChars) {
  // Removes the beginning or trailing spaces, newlines or tabs.
  const trimmedText = text.replace(/^\s+|\s+$/g, '')
  if (!text || trimmedText.length === 0 || maxChars <= 0) {
    return []
  }
  const lines = []
  const words = trimmedText.match(/\S+/g)
  while (words.length) {
    let newLineNeeded = false
    let line = ''
    let word
    while (!newLineNeeded && (word = words.shift())) {
      word = word.trim()
      const newLength = (line + word).length
      if (word.length >= maxChars + 1) {
        // if a single word doesn't fit in a line
        const start = word.substring(0, maxChars - 1)
        const end = word.substring(maxChars - 1)
        line += start + '-'
        words.unshift(end)
        newLineNeeded = line.length >= maxChars
      } else if (newLength) {
        // if a new word can be added in current line
        line += word.trim() + ' '
        newLineNeeded = line.length >= maxChars
      } else {
        // if a new word can't be added in current line
        newLineNeeded = true
      }
    }
    line = line.trim()
    lines.push(line)
  }
  return lines
}

export const decode = input =>
  new DOMParser().parseFromString(input, 'text/html').documentElement.textContent
