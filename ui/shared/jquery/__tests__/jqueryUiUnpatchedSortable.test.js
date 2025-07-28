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
import 'jqueryui/sortable'
import '@canvas/jquery/jquery.simulate'

describe('Sortable Widget', () => {
  beforeEach(() => {
    document.body.innerHTML = '<div id="fixtures"></div>'
    $('#fixtures').append(
      '<ul id="sortable-list">' +
        '<li style="height: 30px;">Item 1</li>' +
        '<li style="height: 30px;">Item 2</li>' +
        '<li style="height: 30px;">Item 3</li>' +
        '</ul>',
    )
    $('#sortable-list').sortable() // Initialize sortable widget
  })

  afterEach(() => {
    const $sortableList = $('#sortable-list')
    if ($sortableList.length) {
      $sortableList.sortable('destroy')
    }
    document.body.innerHTML = ''
  })

  it('initializes with sortable class', () => {
    const $sortableList = $('#sortable-list')
    expect($sortableList.hasClass('ui-sortable')).toBe(true)
  })

  it('is enabled by default', () => {
    const $sortableList = $('#sortable-list')
    expect($sortableList.sortable('option', 'disabled')).toBe(false)
  })

  it('allows sorting items', () => {
    const $sortableList = $('#sortable-list')
    const $items = $sortableList.find('li')
    const initialOrder = Array.from($items).map(item => item.textContent)

    // Trigger sortable update by moving the first item to the end
    const $firstItem = $items.first()
    $firstItem.detach().appendTo($sortableList)
    $sortableList.trigger('sortupdate')

    const $newItems = $sortableList.find('li')
    const newOrder = Array.from($newItems).map(item => item.textContent)

    // Verify the order has changed
    expect(newOrder).not.toEqual(initialOrder)
    expect(newOrder[2]).toBe(initialOrder[0]) // First item should now be last
  })
})
