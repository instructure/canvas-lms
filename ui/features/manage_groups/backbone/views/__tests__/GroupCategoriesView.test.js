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
import 'jquery-migrate'
import GroupCategoriesView from '../GroupCategoriesView'
import GroupCategoryCollection from '@canvas/groups/backbone/collections/GroupCategoryCollection'
import GroupCategory from '@canvas/groups/backbone/models/GroupCategory'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('GroupCategoriesView', () => {
  let view
  let categories
  let wrapper

  beforeEach(() => {
    jest.useFakeTimers()
    fakeENV.setup()
    ENV.group_categories_url = '/api/v1/courses/1/group_categories'
    ENV.permissions = {can_add_groups: true}

    categories = new GroupCategoryCollection([
      {
        id: 1,
        name: 'group set 1',
      },
      {
        id: 2,
        name: 'group set 2',
      },
    ])
    jest.spyOn(categories, 'fetch').mockReturnValue([])

    view = new GroupCategoriesView({collection: categories})
    view.render()

    wrapper = document.createElement('div')
    wrapper.id = 'fixtures'
    document.body.appendChild(wrapper)
    view.$el.appendTo($('#fixtures'))
  })

  afterEach(() => {
    fakeENV.teardown()
    jest.useRealTimers()
    view.remove()
    document.body.removeChild(wrapper)
  })

  it('renders tab and panel elements', () => {
    // find the tabs
    expect(view.$el.find('.collectionViewItems > li')).toHaveLength(2)
    // find the panels
    expect(view.$el.find('#tab-1')).toHaveLength(1)
    expect(view.$el.find('#tab-2')).toHaveLength(1)
  })

  it('adds new GroupCategory and displays new tab and panel', () => {
    categories.add(
      new GroupCategory({
        id: 3,
        name: 'Newly Added',
      }),
    )
    expect(view.$el.find('.collectionViewItems > li')).toHaveLength(3)
    expect(view.$el.find('#tab-3')).toHaveLength(1)
  })

  it('removes GroupCategory and removes tab and panel', () => {
    categories.remove(categories.models[0])
    expect(view.$el.find('.collectionViewItems > li')).toHaveLength(1)
    expect(view.$el.find('#tab-1')).toHaveLength(0)
    categories.remove(categories.models[0])
    expect(view.$el.find('.collectionViewItems > li')).toHaveLength(0)
    expect(view.$el.find('#tab-2')).toHaveLength(0)
  })

  it('loads tab panel content when tab is activated', () => {
    // verify the content is not present before being activated
    expect($('#tab-2').children()).toHaveLength(0)
    // activate
    view.$el.find('.group-category-tab-link:last').click()
    expect($('#tab-2').children().length).toBeGreaterThan(0)
  })
})
