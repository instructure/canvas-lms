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
import 'jqueryui/tabs'

QUnit.module('tabs widget', {
  beforeEach() {
    const tabsHTML = `
      <div id="tabs">
        <ul>
          <li><a href="#tab-1">Tab 1</a></li>
          <li><a href="#tab-2">Tab 2</a></li>
        </ul>
        <div id="tab-1">Content for tab 1</div>
        <div id="tab-2">Content for tab 2</div>
      </div>
    `
    $('#fixtures').append(tabsHTML)
    $('#tabs').tabs()
  },
  afterEach() {
    $('#fixtures').empty()
    $('#tabs').tabs('destroy').remove()
  },
})

QUnit.test('tabs widget is initialized', function (assert) {
  const $tabs = $('#tabs')
  const $activeTab = $tabs.find('.ui-tabs-active')
  assert.ok($tabs.hasClass('ui-tabs'), 'Tabs container has class ui-tabs')
  assert.equal($activeTab.length, 1, 'One tab is active')
  assert.equal($activeTab.find('a').attr('href'), '#tab-1', 'First tab is active')
  assert.equal($tabs.find('.ui-tabs-panel').length, 2, 'Two tab panels exist')
})

QUnit.test('switching tabs changes active tab', function (assert) {
  const $tabs = $('#tabs')
  const $tabLinks = $tabs.find('a')
  $tabLinks.eq(1).click()
  assert.equal(
    $tabs.find('.ui-tabs-active a').attr('href'),
    '#tab-2',
    'Second tab is active after clicking'
  )
})

QUnit.test('Only active tab content is visible', function (assert) {
  const $tabs = $('#tabs')
  const $tab1Content = $('#tab-1')
  const $tab2Content = $('#tab-2')
  assert.ok($tab1Content.is(':visible'), 'Tab 1 content is visible initially')
  assert.notOk($tab2Content.is(':visible'), 'Tab 2 content is hidden initially')
  $tabs.find('a[href="#tab-2"]').click()
  assert.notOk($tab1Content.is(':visible'), 'Tab 1 content is hidden after switching')
  assert.ok($tab2Content.is(':visible'), 'Tab 2 content is visible after switching')
})

QUnit.test('Clicking on a tab triggers expected event', function (assert) {
  const $tabs = $('#tabs')
  const done = assert.async()
  $tabs.on('tabsactivate', function (event, ui) {
    assert.ok(ui.newTab.is('li'), 'New tab is a list item')
    assert.ok(ui.newPanel.is('div'), 'New panel is a div element')
    done()
  })
  $tabs.find('a[href="#tab-2"]').click()
})

QUnit.test('Destroying tabs removes associated UI elements and bindings', function (assert) {
  const $tabs = $('#tabs')
  assert.ok($tabs.length, 'Tabs container exists before destroying')
  $tabs.tabs('destroy')
  $tabs.remove()
  // must re-cache #tabs after removing it
  assert.notOk($('#tabs').length, 'Tabs container is removed')
  assert.notOk($('.ui-tabs-nav').length, 'Tabs navigation is removed')
  assert.notOk($('.ui-tabs-panel').length, 'Tab panels are removed')
})
