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

import {Editor} from 'tinymce'

export const IGNORE_WORDCOUNT_ATTRIBUTE = 'data-ignore-wordcount'

export type Scope = 'body' | 'selection'
export type Category = 'words' | 'chars-no-spaces' | 'chars'

export const countWords = (node: Element): number => {
  if (node.getAttribute(IGNORE_WORDCOUNT_ATTRIBUTE) === 'chars-only') return 0
  const textContent = (node as HTMLElement)?.innerText || ''
  const trimmedTextContent = textContent.trim()
  if (trimmedTextContent.length === 0) return 0
  return trimmedTextContent.split(/\s+/).length
}

export const countCharsNoSpaces = (node: Element): number => {
  const textContent = (node as HTMLElement)?.innerText || ''
  const matches = textContent.match(/ /g) // a single space
  const spaces = matches ? matches.length : 0
  return countChars(node) - spaces
}

export const countChars = (node: Element): number => {
  const textContent = (node as HTMLElement)?.innerText || ''
  const iterator = textContent[Symbol.iterator]()
  let count = 0
  while (!iterator.next().done) {
    count++
  }
  return count
}

export const callbackForCategory = (category: Category): ((node: Element) => number) => {
  switch (category) {
    case 'words':
      return countWords
    case 'chars-no-spaces':
      return countCharsNoSpaces
    case 'chars':
      return countChars
  }
}

export const countShouldIgnore = (ed: Editor, scope: Scope, category: Category): number => {
  if (scope === 'selection') return 0
  const nodesToCount = Array.from(ed.getBody().querySelectorAll(`[${IGNORE_WORDCOUNT_ATTRIBUTE}]`))
  const callback = callbackForCategory(category)
  return nodesToCount.reduce((total, node) => total + callback(node), 0)
}

export const getTinymceCount = (ed: Editor, scope: Scope, category: Category): number => {
  const wc = ed.plugins.wordcount[scope]
  switch (category) {
    case 'words':
      return wc.getWordCount()
    case 'chars-no-spaces':
      return wc.getCharacterCountWithoutSpaces()
    case 'chars':
      return wc.getCharacterCount()
  }
}

export const countContent = (ed: Editor, scope: Scope, category: Category): number => {
  return getTinymceCount(ed, scope, category) - countShouldIgnore(ed, scope, category)
}
