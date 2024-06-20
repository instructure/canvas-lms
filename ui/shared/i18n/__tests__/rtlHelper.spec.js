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

// this is a QUnit test and not a jest test because it needs a real DOM to pick on the dir='rtl' stuff

import {direction} from '../rtlHelper'

describe('rtlHelper', () => {
  describe('.direction', () => {
    let el

    beforeEach(() => {
      el = document.createElement('div')
      document.body.appendChild(el)
    })

    afterEach(() => {
      document.body.removeChild(el)
    })

    test('returns the same word you pass it for an LTR element', () => {
      expect(direction('left', el)).toBe('left')
      expect(direction('right', el)).toBe('right')
    })

    test('uses dir of <html> tag by default', () => {
      expect(direction('left')).toBe('left')
      expect(direction('right')).toBe('right')
    })

    test('flips if the [dir=rtl]', () => {
      el.setAttribute('dir', 'rtl')
      expect(direction('left', el)).toBe('right')
      expect(direction('right', el)).toBe('left')
    })
  })
})
