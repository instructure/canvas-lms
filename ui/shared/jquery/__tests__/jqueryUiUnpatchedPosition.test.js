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

import $ from 'jquery'
import 'jquery-migrate' // required
import 'jqueryui/position'

describe('jQuery UI Position Tests', () => {
  beforeEach(() => {
    document.body.innerHTML = '<div id="qunit-fixture"></div>'
    $('#qunit-fixture').append('<div id="position-element"></div>')
  })

  afterEach(() => {
    $('#qunit-fixture').empty()
  })

  test('Position element relative to window', () => {
    // Create element we will be positioning
    const $positionElement = $('#position-element')

    // Position the element at the top left of the window
    $positionElement.position({
      my: 'left top',
      at: 'left top',
      of: window,
    })

    // Element be positioned at the top left of the window
    const offset = $positionElement.offset()
    expect(offset.left).toBe(0)
    expect(offset.top).toBe(0)
  })

  // fails in Jest, passes in QUnit
  test.skip('Position element relative to another element', () => {
    // Create element we will be positioning
    const $positionElement = $('#position-element')
    // Create target element we will be positioning relative to
    $('#qunit-fixture').append('<div id="target-element" style="width: 50px; height: 50px;"></div>')

    // Position the top-left corner of the element at the bottom-right corner of the target
    $positionElement.position({
      my: 'left top',
      at: 'right bottom',
      of: '#target-element',
    })

    // Get coordinates of each element
    const offset = $positionElement.offset()
    const targetOffset = $('#target-element').offset()

    // Assertions
    expect(offset.left).toBeGreaterThan(targetOffset.left)
    expect(offset.top).toBeGreaterThan(targetOffset.top)
  })
})
