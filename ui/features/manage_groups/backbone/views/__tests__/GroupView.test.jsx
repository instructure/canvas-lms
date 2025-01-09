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
import GroupView from '../GroupView'
import GroupUsersView from '../GroupUsersView'
import GroupDetailView from '../GroupDetailView'
import GroupUserCollection from '@canvas/groups/backbone/collections/GroupUserCollection'
import Group from '@canvas/groups/backbone/models/Group'
import axe from 'axe-core'

describe('GroupView', () => {
  let view
  let group
  let users
  let container

  const createView = () => {
    group = new Group({
      id: 42,
      name: 'Foo Group',
      members_count: 7,
    })

    users = new GroupUserCollection(
      [
        {
          id: 1,
          name: 'bob',
          sortable_name: 'bob',
        },
        {
          id: 2,
          name: 'joe',
          sortable_name: 'joe',
        },
      ],
      {group},
    )
    users.loaded = true
    users.loadedAll = true
    group.users = () => users
    group.set('leader', {id: 1})

    const groupUsersView = new GroupUsersView({
      model: group,
      collection: users,
    })

    const groupDetailView = new GroupDetailView({
      model: group,
      users,
    })

    view = new GroupView({
      groupUsersView,
      groupDetailView,
      model: group,
    })

    container = document.createElement('div')
    container.id = 'fixtures'
    container.setAttribute('role', 'main')
    container.setAttribute('aria-label', 'Group Management')
    document.body.appendChild(container)

    const list = document.createElement('ul')
    list.setAttribute('role', 'list')
    list.setAttribute('aria-label', 'Groups')
    container.appendChild(list)

    view.render()
    view.$el.appendTo($(list))

    return view
  }

  beforeEach(() => {
    window.ENV = {
      permissions: {can_add_groups: true},
    }
    createView()
  })

  afterEach(() => {
    window.ENV = null
    if (container) {
      container.remove()
      container = null
    }
    view.remove()
    jest.restoreAllMocks()
  })

  const assertCollapsed = view => {
    expect(view.$el.hasClass('group-collapsed')).toBe(true)
    expect(view.$el.hasClass('group-expanded')).toBe(false)
  }

  const assertExpanded = view => {
    expect(view.$el.hasClass('group-collapsed')).toBe(false)
    expect(view.$el.hasClass('group-expanded')).toBe(true)
  }

  it('is accessible', async () => {
    const results = await axe.run(container, {
      rules: {
        'color-contrast': {enabled: false}, // Disable color contrast check since we're testing in a detached DOM
      },
      runOnly: ['wcag2a', 'wcag2aa'],
    })
    expect(results.violations).toHaveLength(0)
  })

  it('renders in collapsed state initially', () => {
    assertCollapsed(view)
  })

  it('expands and collapses when toggle button is clicked', () => {
    assertCollapsed(view)

    view.$('.toggle-group').eq(0).click()

    assertExpanded(view)

    view.$('.toggle-group').eq(0).click()

    assertCollapsed(view)
  })

  it('renders group users', () => {
    expect(view.$('.group-user')).toHaveLength(2)
  })

  it('removes the group after successful deletion', () => {
    jest.spyOn(window, 'confirm').mockImplementation(() => true)
    const removeSpy = jest.spyOn(view, 'remove')
    view.attach() // Ensure event listeners are attached

    view.model.trigger('destroy')

    expect(removeSpy).toHaveBeenCalled()
  })
})
