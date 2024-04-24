/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

const NUMBER_OF_WORDS = 10

const countWords = (text: string) => {
  // ignore text before the first whitespace because it is part of the selected text
  const countText = text.split(/\s+/).slice(1).join(' ')
  const count = countText.trim().split(/\s+/).length
  return count
}

const getAfterText = (startingElement: Element) => {
  let text = ''
  let element = startingElement.nextSibling
  while (element) {
    text += element.textContent
    element = element.nextSibling
  }

  if (text.includes('.')) {
    const index = text.indexOf('.')
    text = text.substring(0, index + 1)
  }

  if (countWords(text) > NUMBER_OF_WORDS) {
    text = text
      .split(/\s+/)
      .slice(0, NUMBER_OF_WORDS + 1)
      .join(' ')
  }
  return text
}

const getBeforeText = (startingElement: Element, wordCount: number) => {
  let text = ''
  let element = startingElement.previousSibling

  while (element) {
    text = element.textContent + text
    element = element.previousSibling
  }

  text = text
    .split(/\s+/)
    .slice(-wordCount - 1)
    .join(' ')

  return text
}

export const getSelectionContext = (elements: HTMLCollectionOf<Element>) => {
  const firstSelected = elements[0]
  const lastSelected = elements[elements.length - 1]

  const afterText = getAfterText(lastSelected)
  const remainingWordCount = Math.max(NUMBER_OF_WORDS - countWords(afterText), 0)
  const beforeText = getBeforeText(firstSelected, remainingWordCount)

  return [beforeText, afterText]
}
