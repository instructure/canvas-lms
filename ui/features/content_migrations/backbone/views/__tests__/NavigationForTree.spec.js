/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import NavigationForTree from '../NavigationForTree'
import $ from 'jquery'
import 'jquery-migrate'

describe('Navigation: Click Tests', () => {
  let $tree

  beforeEach(() => {
    // Setting up the DOM element in jsdom
    document.body.innerHTML = `
      <div id='fixtures'>
        <ul role='tree'>
          <li role='treeitem' id='42'>
            <div class='treeitem-heading'>Heading Text</div>
          </li>
        </ul>
      </div>
    `
    $tree = $('[role=tree]')
    new NavigationForTree($tree) // Assuming NavigationForTree initializes event listeners
  })

  afterEach(() => {
    // Cleaning up the DOM
    $('#fixtures').empty()
  })

  test('clicking treeitem heading selects that tree item', () => {
    const $heading = $('.treeitem-heading')
    const $treeitem = $heading.closest('[role=treeitem]')
    $heading.click()

    // Using Jest's expect for assertions
    expect($treeitem.attr('aria-selected')).toBeTruthy()
    expect($tree.attr('aria-activedescendant')).toBe($treeitem.attr('id'))
  })
})
