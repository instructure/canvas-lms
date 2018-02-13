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

import $ from 'jquery'
import GroupCategoriesView from 'compiled/views/groups/manage/GroupCategoriesView'
import GroupCategoryCollection from 'compiled/collections/GroupCategoryCollection'
import GroupCategory from 'compiled/models/GroupCategory'
import fakeENV from 'helpers/fakeENV'

let clock = null
let view = null
let categories = null
let wrapper = null
const sanbox = null

QUnit.module('GroupCategoriesView', {
  setup() {
    fakeENV.setup()
    ENV.group_categories_url = '/api/v1/courses/1/group_categories'
    clock = sinon.useFakeTimers()
    categories = new GroupCategoryCollection([
      {
        id: 1,
        name: 'group set 1'
      },
      {
        id: 2,
        name: 'group set 2'
      }
    ])
    this.stub(categories, 'fetch').returns([])
    view = new GroupCategoriesView({collection: categories})
    view.render()
    wrapper = document.getElementById('fixtures')
    wrapper.innerHTML = ''
    view.$el.appendTo($('#fixtures'))
  },
  teardown() {
    fakeENV.teardown()
    clock.restore()
    view.remove()
    wrapper.innerHTML = ''
  }
})

test('render tab and panel elements', () => {
  // find the tabs
  equal(view.$el.find('.collectionViewItems > li').length, 2)
  // find the panels
  equal(view.$el.find('#tab-1').length, 1)
  equal(view.$el.find('#tab-2').length, 1)
})

test('adding new GroupCategory should display new tab and panel', () => {
  categories.add(
    new GroupCategory({
      id: 3,
      name: 'Newly Added'
    })
  )
  equal(view.$el.find('.collectionViewItems > li').length, 3)
  equal(view.$el.find('#tab-3').length, 1)
})

test('removing GroupCategory should remove tab and panel', () => {
  categories.remove(categories.models[0])
  equal(view.$el.find('.collectionViewItems > li').length, 1)
  equal(view.$el.find('#tab-1').length, 0)
  categories.remove(categories.models[0])
  equal(view.$el.find('.collectionViewItems > li').length, 0)
  equal(view.$el.find('#tab-2').length, 0)
})

test('tab panel content should be loaded when tab is activated', () => {
  // verify the content is not present before being activated
  equal($('#tab-2').children().length, 0)
  // activate
  view.$el.find('.group-category-tab-link:last').click()
  ok($('#tab-2').children().length > 0)
})
