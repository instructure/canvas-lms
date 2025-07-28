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

import getTextWidth from '../TextMeasure'

describe('TextMeasure', () => {
  let $fixture

  beforeEach(() => {
    $fixture = document.createElement('div')
    document.body.appendChild($fixture)

    $fixture.innerHTML = '<div id="content"></div>'
  })

  afterEach(() => {
    $fixture.remove()
  })

  describe('getTextWidth', () => {
    test('returns a numerical width for the given text', () => {
      const width = getTextWidth('example')
      expect(typeof width).toBe('number')
    })

    test('returns integers', () => {
      const width = getTextWidth('example')
      expect(width).toBe(Math.floor(width))
    })

    test('returns larger numbers for wider text', () => {
      const orderedWords = ['a', 'aa', 'aaa']
      const orderedWidths = ['aaa', 'a', 'aa'].map(getTextWidth).sort((a, b) => a - b)
      expect(orderedWidths).toEqual(orderedWords.map(getTextWidth))
    })

    test('creates a "text-measure" element attached to the "content" element', () => {
      getTextWidth('example')
      const $textMeasure = document.getElementById('text-measure')
      expect($textMeasure.parentElement).toBe(document.getElementById('content'))
    })

    test('creates only one "text-measure" element', () => {
      getTextWidth('example')
      getTextWidth('sample')
      expect(document.getElementById('content').children).toHaveLength(1)
    })
  })
})
