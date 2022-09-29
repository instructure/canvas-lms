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

import getTextWidth from 'ui/features/gradebook/react/shared/helpers/TextMeasure'

QUnit.module('TextMeasure', hooks => {
  let $fixture

  hooks.beforeEach(() => {
    $fixture = document.createElement('div')
    document.body.appendChild($fixture)

    $fixture.innerHTML = '<div id="content"></div>'
  })

  hooks.afterEach(() => {
    $fixture.remove()
  })

  QUnit.module('getTextWidth', () => {
    test('returns a numerical width for the given text', () => {
      const width = getTextWidth('example')
      equal(typeof width, 'number')
    })

    test('returns integers', () => {
      const width = getTextWidth('example')
      strictEqual(width, Math.floor(width))
    })

    test('returns larger numbers for wider text', () => {
      const orderedWords = ['a', 'aa', 'aaa']
      const orderedWidths = ['aaa', 'a', 'aa'].map(getTextWidth).sort()
      deepEqual(orderedWidths, orderedWords.map(getTextWidth))
    })

    test('creates a "text-measure" element attached to the "content" element', () => {
      getTextWidth('example')
      const $textMeasure = document.getElementById('text-measure')
      equal($textMeasure.parentElement, document.getElementById('content'))
    })

    test('creates only one "text-measure" element', () => {
      getTextWidth('example')
      getTextWidth('sample')
      strictEqual(document.getElementById('content').children.length, 1)
    })
  })
})
