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

import {direction} from 'jsx/shared/helpers/rtlHelper'

QUnit.module('rtlHelper', () => {
  QUnit.module('.direction', (hooks) => {
    
    let el
    hooks.beforeEach(() => {
      el = document.createElement('div')
      document.body.appendChild(el)
    })
    hooks.afterEach(() => {
      document.body.removeChild(el)
    })

    test('returns the same word you pass it for an LTR element', () => {
      equal(direction('left', el), 'left')
      equal(direction('right', el), 'right')
    })

    test('uses dir of <html> tag by default', () => {
      equal(direction('left'), 'left')
      equal(direction('right'), 'right')
    })

    test('flips if the [dir=rtl]', () => {
      el.setAttribute('dir', 'rtl')
      equal(direction('left', el), 'right')
      equal(direction('right', el), 'left')
    })
  })
})