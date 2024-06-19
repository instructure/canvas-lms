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
import 'jqueryui/mouse'

const container = document.createElement('div')
container.setAttribute('id', 'fixtures')
document.body.appendChild(container)

const ok = value => expect(value).toBeTruthy()

describe('Mouse Widget', () => {
  beforeEach(() => {
    $('#fixtures').append('<div id="test-mouse">Test Mouse</div>')
  })

  afterEach(() => {
    $('#fixtures').empty()
  })

  it('Mouse down event fires', function (done) {
    const $mouse = $('#test-mouse')

    // setup mouse events
    $mouse.mousedown(() => {
      ok(true)
      done()
    })

    // make the call we are testing: Trigger mousedown event
    $mouse.trigger('mousedown')
  })

  it('Mouse up event fires', function (done) {
    const $mouse = $('#test-mouse')

    // setup mouse events
    $mouse.mouseup(() => {
      ok(true)
      done()
    })

    // make the call we are testing: Trigger mouse up event
    $mouse.trigger('mouseup')
  })
})
