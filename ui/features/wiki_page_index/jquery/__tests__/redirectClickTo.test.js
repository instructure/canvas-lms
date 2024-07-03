/*
 * Copyright (C) 2013 - present Instructure, Inc.
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
import '../redirectClickTo' // Assuming this adds a method to jQuery objects

describe('redirectClickTo', () => {
  const createClick = () => {
    const e = new MouseEvent('click', {
      bubbles: true,
      cancelable: true,
      ctrlKey: true,
      shiftKey: false,
      altKey: false,
      metaKey: false,
      button: 2, // Right click
    })
    return e
  }

  test('redirects clicks', () => {
    document.body.innerHTML = `
      <div id="sourceDiv"></div>
      <div id="targetDiv"></div>
    `

    const sourceDiv = $('#sourceDiv')
    const targetDiv = $('#targetDiv')
    const targetDivSpy = jest.fn()

    targetDiv.on('click', targetDivSpy)
    sourceDiv.redirectClickTo(targetDiv)
    const e = createClick()

    sourceDiv.get(0).dispatchEvent(e)

    expect(targetDivSpy).toHaveBeenCalled()
    expect(targetDivSpy.mock.calls[0][0].type).toBe(e.type)
    expect(targetDivSpy.mock.calls[0][0].ctrlKey).toBe(e.ctrlKey)
    expect(targetDivSpy.mock.calls[0][0].altKey).toBe(e.altKey)
    expect(targetDivSpy.mock.calls[0][0].shiftKey).toBe(e.shiftKey)
    expect(targetDivSpy.mock.calls[0][0].metaKey).toBe(e.metaKey)
    expect(targetDivSpy.mock.calls[0][0].button).toBe(e.button)
  })
})
