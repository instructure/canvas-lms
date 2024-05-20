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

import NavigationForTree from 'ui/features/content_migrations/backbone/views/NavigationForTree'
import $ from 'jquery'
import 'jquery-migrate'

QUnit.module('Navigation: Click Tests', {
  setup() {
    $('#fixtures').html(`
      <ul role='tree'>
        <li role='treeitem' id='42'>
          <div class='treeitem-heading'>Heading Text</div>
        </li>
      </ul>
    `)
    this.$tree = $('[role=tree]')
    this.nft = new NavigationForTree(this.$tree)
  },
  teardown() {
    return $('#fixtures').html('')
  },
})

test('clicking treeitem heading selects that tree item', function () {
  const $heading = this.$tree.find('.treeitem-heading')
  const $treeitem = $heading.closest('[role=treeitem]')
  $heading.click()
  ok(!!$treeitem.attr('aria-selected'))
  equal(this.$tree.attr('aria-activedescendant'), $treeitem.attr('id'))
})
