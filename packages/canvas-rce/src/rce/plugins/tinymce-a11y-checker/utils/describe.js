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

import formatMessage from '../../../../format-message'
import * as strings from './strings'

const WORD_COUNT = 4

export default function describe(elem) {
  if (!elem || !elem.tagName) {
    return null
  }

  switch (elem.tagName) {
    case 'IMG':
      return formatMessage('Image with filename {file}', {
        file: strings.filename(elem.src),
      })
    case 'TABLE':
      return formatMessage('Table starting with {start}', {
        start: strings.firstWords(elem.textContent, WORD_COUNT),
      })
    case 'A':
      return formatMessage('Link with text starting with {start}', {
        start: strings.firstWords(elem.textContent, WORD_COUNT),
      })
    case 'P':
      return formatMessage('Paragraph starting with {start}', {
        start: strings.firstWords(elem.textContent, WORD_COUNT),
      })
    case 'TH':
      return formatMessage('Table header starting with {start}', {
        start: strings.firstWords(elem.textContent, WORD_COUNT),
      })
    case 'H1':
    case 'H2':
    case 'H3':
    case 'H4':
    case 'H5':
      return formatMessage('Heading starting with {start}', {
        start: strings.firstWords(elem.textContent, WORD_COUNT),
      })
    default:
      return formatMessage('Element starting with {start}', {
        start: strings.firstWords(elem.textContent, WORD_COUNT),
      })
  }
}
