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
import 'jqueryui/resizable'

describe('Resizable Widget', () => {
  beforeEach(() => {
    document.body.innerHTML = '<div id="fixtures"></div>'
    $('#fixtures').append(
      '<div id="resizable-element" style="width: 100px; height: 100px;">Resizable Element</div>',
    )
    $('#resizable-element').resizable()
  })

  afterEach(() => {
    document.body.innerHTML = ''
  })

  it('initializes with resizable class', () => {
    const $resizableElement = $('#resizable-element')
    expect($resizableElement.hasClass('ui-resizable')).toBe(true)
  })

  it('triggers resize event', () => {
    const $resizableElement = $('#resizable-element')
    const resizeHandler = jest.fn()

    $resizableElement.on('resize', resizeHandler)
    $resizableElement.trigger('resize')

    expect(resizeHandler).toHaveBeenCalled()
  })
})
