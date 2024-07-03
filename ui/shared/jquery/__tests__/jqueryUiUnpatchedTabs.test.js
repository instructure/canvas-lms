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

const ok = x => expect(x).toBeTruthy()
const notOk = x => expect(x).toBeFalsy()
const equal = (a, b) => expect(a).toBe(b)

const container = document.createElement('div')
container.setAttribute('id', 'fixtures')
document.body.appendChild(container)

describe('tabs widget', () => {
  beforeEach(() => {
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
  })

  afterEach(() => {
    $('#fixtures').empty()
    $('#tabs').tabs('destroy').remove()
  })

  test('tabs widget is initialized', function () {
    const $tabs = $('#tabs')
    const $activeTab = $tabs.find('.ui-tabs-active')
    ok($tabs.hasClass('ui-tabs'), 'Tabs container has class ui-tabs')
    equal($activeTab.length, 1, 'One tab is active')
    equal($activeTab.find('a').attr('href'), '#tab-1', 'First tab is active')
    equal($tabs.find('.ui-tabs-panel').length, 2, 'Two tab panels exist')
  })

  test('switching tabs changes active tab', function () {
    const $tabs = $('#tabs')
    const $tabLinks = $tabs.find('a')
    $tabLinks.eq(1).click()
    equal(
      $tabs.find('.ui-tabs-active a').attr('href'),
      '#tab-2',
      'Second tab is active after clicking'
    )
  })

  // jsdom doesn't support :visible
  test.skip('Only active tab content is visible', function () {
    const $tabs = $('#tabs')
    const $tab1Content = $('#tab-1')
    const $tab2Content = $('#tab-2')
    ok($tab1Content.is(':visible'), 'Tab 1 content is visible initially')
    notOk($tab2Content.is(':visible'), 'Tab 2 content is hidden initially')
    $tabs.find('a[href="#tab-2"]').click()
    notOk($tab1Content.is(':visible'), 'Tab 1 content is hidden after switching')
    ok($tab2Content.is(':visible'), 'Tab 2 content is visible after switching')
  })

  test('Clicking on a tab triggers expected event', function (done) {
    const $tabs = $('#tabs')
    $tabs.on('tabsactivate', function (event, ui) {
      ok(ui.newTab.is('li'), 'New tab is a list item')
      ok(ui.newPanel.is('div'), 'New panel is a div element')
      done()
    })
    $tabs.find('a[href="#tab-2"]').click()
  })

  test('Destroying tabs removes associated UI elements and bindings', function () {
    const $tabs = $('#tabs')
    ok($tabs.length, 'Tabs container exists before destroying')
    $tabs.tabs('destroy')
    $tabs.remove()
    // must re-cache #tabs after removing it
    notOk($('#tabs').length, 'Tabs container is removed')
    notOk($('.ui-tabs-nav').length, 'Tabs navigation is removed')
    notOk($('.ui-tabs-panel').length, 'Tab panels are removed')
  })
})
