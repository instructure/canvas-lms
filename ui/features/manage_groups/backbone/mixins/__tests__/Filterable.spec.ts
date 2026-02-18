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

import Filterable from '../Filterable'
import {Collection, View} from '@canvas/backbone'
import CollectionView from '@canvas/backbone-collection-view'
import fakeENV from '@canvas/test-utils/fakeENV'
import $ from 'jquery'

// @ts-expect-error - Legacy Backbone typing
let view = null

describe('Filterable', () => {
  beforeEach(() => {
    fakeENV.setup()
    class MyCollectionView extends CollectionView {
      static initClass() {
        // @ts-expect-error - Backbone View property
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
    view.render()
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  test("hides items that don't match the filter", () => {
    // @ts-expect-error - Legacy Backbone typing
    expect(view.$list.children()).toHaveLength(2)
    // @ts-expect-error - Legacy Backbone typing
    expect(view.$list.children('.hidden')).toHaveLength(0)

    // @ts-expect-error - Legacy Backbone typing
    view.$filter.val('b')
    // @ts-expect-error - Legacy Backbone typing
    view.$filter.trigger('input')
    // @ts-expect-error - Legacy Backbone typing
    expect(view.$list.children()).toHaveLength(2)
    // @ts-expect-error - Legacy Backbone typing
    expect(view.$list.children('.hidden')).toHaveLength(1)

    // @ts-expect-error - Legacy Backbone typing
    view.$filter.val('bb')
    // @ts-expect-error - Legacy Backbone typing
    view.$filter.trigger('input')
    // @ts-expect-error - Legacy Backbone typing
    expect(view.$list.children()).toHaveLength(2)
    // @ts-expect-error - Legacy Backbone typing
    expect(view.$list.children('.hidden')).toHaveLength(2)

    // @ts-expect-error - Legacy Backbone typing
    view.$filter.val('B')
    // @ts-expect-error - Legacy Backbone typing
    view.$filter.trigger('input')
    // @ts-expect-error - Legacy Backbone typing
    expect(view.$list.children()).toHaveLength(2)
    // @ts-expect-error - Legacy Backbone typing
    expect(view.$list.children('.hidden')).toHaveLength(1)
  })
})
