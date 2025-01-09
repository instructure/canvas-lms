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
import '../jquery.simulate'
import 'jqueryui/droppable'

describe('Droppable Widget', () => {
  beforeEach(() => {
    document.body.innerHTML = '<div id="fixtures"></div>'
    $('#fixtures').append(
      '<div id="droppable-element" style="width: 100px; height: 100px; background: blue;">Droppable Element</div>',
    )
    $('#droppable-element').droppable()
  })

  afterEach(() => {
    document.body.innerHTML = ''
  })

  it('initializes with droppable class', () => {
    const $droppableElement = $('#droppable-element')
    expect($droppableElement.hasClass('ui-droppable')).toBe(true)
  })

  it('triggers drop event', () => {
    const $droppableElement = $('#droppable-element')
    const dropHandler = jest.fn()

    $droppableElement.on('drop', dropHandler)
    $droppableElement.trigger('drop')

    expect(dropHandler).toHaveBeenCalled()
  })

  it('accepts draggable elements', () => {
    const $droppableElement = $('#droppable-element')
    const $draggableElement = $(
      '<div class="draggable" style="width: 50px; height: 50px; background: red;"></div>',
    )
      .appendTo('#fixtures')
      .draggable()

    expect($droppableElement.droppable('option', 'accept')).toBe('*')
    expect($draggableElement.is($droppableElement.droppable('option', 'accept'))).toBe(true)
  })

  it('has correct default options', () => {
    const $droppableElement = $('#droppable-element')
    const options = $droppableElement.droppable('option')

    expect(options.disabled).toBe(false)
    expect(options.accept).toBe('*')
    expect(options.addClasses).toBe(true)
    expect(options.greedy).toBe(false)
  })
})
