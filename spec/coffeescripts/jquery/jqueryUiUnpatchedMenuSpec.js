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
import '@canvas/jquery/jquery.simulate'

QUnit.module('Menu Widget', {
  setup() {
    $('#fixtures').append('<ul id="menu"><li>Item 1</li><li>Item 2</li><li>Item 3</li></ul>')
    this.$menu = $('#menu').menu()
  },
  teardown() {
    $('#fixtures').empty()
    $('#menu').menu('destroy')
    $('#menu').remove()
  },
})

QUnit.test('Check menu initialization', function (assert) {
  const $menu = $('#menu')
  const isInitialized = $menu.hasClass('ui-menu')
  assert.ok(isInitialized, 'Menu is initialized with ui-menu class')
})

QUnit.test('Check menu item selection', function (assert) {
  const $menuItems = this.$menu.find('li')

  $menuItems.first().trigger('click')
  const isFirstActive = $('#menu').menu('isFirstItem')

  assert.ok(isFirstActive, 'Clicked menu item is active')
})

QUnit.test('Check submenu opening', function (assert) {
  const $menu = $('#menu')
  const $firstItem = $menu.find('li').first()
  $('<ul><li><a href="#">Submenu Item</a></li></ul>').appendTo($firstItem)
  $firstItem.menu()

  const $submenuItems = $firstItem.find('li')

  $submenuItems.first().trigger('click')
  const isSubMenuFirstActive = $firstItem.menu('isFirstItem')

  assert.ok(isSubMenuFirstActive, 'Clicked menu item is active')
})
