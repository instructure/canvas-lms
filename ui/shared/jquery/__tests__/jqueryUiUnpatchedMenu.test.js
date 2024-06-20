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
 * WARRANTY without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import 'jqueryui/menu'
import '../jquery.simulate'

const container = document.createElement('div')
container.setAttribute('id', 'fixtures')
document.body.appendChild(container)

let $menu

const ok = value => expect(value).toBeTruthy()

describe('Menu Widget', () => {
  beforeEach(() => {
    $('#fixtures').append('<ul id="menu"><li>Item 1</li><li>Item 2</li><li>Item 3</li></ul>')
    $menu = $('#menu').menu()
  })

  afterEach(() => {
    $('#fixtures').empty()
    $('#menu').menu('destroy')
    $('#menu').remove()
  })

  test('Check menu initialization', function () {
    const $menu_ = $('#menu')
    const isInitialized = $menu_.hasClass('ui-menu')
    ok(isInitialized, 'Menu is initialized with ui-menu class')
  })

  test('Check menu item selection', function () {
    const $menuItems = $menu.find('li')

    $menuItems.first().trigger('click')
    const isFirstActive = $('#menu').menu('isFirstItem')

    ok(isFirstActive, 'Clicked menu item is active')
  })

  test('Check submenu opening', function () {
    const $menu_ = $('#menu')
    const $firstItem = $menu_.find('li').first()
    $('<ul><li><a href="#">Submenu Item</a></li></ul>').appendTo($firstItem)
    $firstItem.menu()

    const $submenuItems = $firstItem.find('li')

    $submenuItems.first().trigger('click')
    const isSubMenuFirstActive = $firstItem.menu('isFirstItem')

    ok(isSubMenuFirstActive, 'Clicked menu item is active')
  })
})
