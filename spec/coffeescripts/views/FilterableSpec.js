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

import Filterable from 'ui/features/manage_groups/backbone/mixins/Filterable'
import {Collection, View} from '@canvas/backbone'
import CollectionView from '@canvas/backbone-collection-view'
import fakeENV from 'helpers/fakeENV'

let view = null

QUnit.module('Filterable', {
  setup() {
    fakeENV.setup()
    class MyCollectionView extends CollectionView {
      static initClass() {
        this.mixin(Filterable)
      }

      template() {
        return `\
<input class="filterable">
<div class="collectionViewItems"></div>\
`
      }
    }
    MyCollectionView.initClass()
    const collection = new Collection([
      {
        id: 1,
        name: 'bob',
      },
      {
        id: 2,
        name: 'joe',
      },
    ])
    view = new MyCollectionView({
      collection,
      itemView: View,
    })
    return view.render()
  },
  teardown() {
    fakeENV.teardown()
  },
})

test("hides items that don't match the filter", () => {
  equal(view.$list.children().length, 2)
  equal(view.$list.children('.hidden').length, 0)
  view.$filter.val('b')
  view.$filter.trigger('input')
  equal(view.$list.children().length, 2)
  equal(view.$list.children('.hidden').length, 1)
  view.$filter.val('bb')
  view.$filter.trigger('input')
  equal(view.$list.children().length, 2)
  equal(view.$list.children('.hidden').length, 2)
  view.$filter.val('B')
  view.$filter.trigger('input')
  equal(view.$list.children().length, 2)
  equal(view.$list.children('.hidden').length, 1)
})
