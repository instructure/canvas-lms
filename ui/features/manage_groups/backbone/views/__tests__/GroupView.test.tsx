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
  // @ts-expect-error - Legacy Backbone typing
  let view
  let group
  // @ts-expect-error - Legacy Backbone typing
  let users
  // @ts-expect-error - Legacy Backbone typing
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
    // @ts-expect-error - Legacy Backbone typing
    group.users = () => users
    // @ts-expect-error - Backbone View property
    group.set('leader', {id: 1})

    const groupUsersView = new GroupUsersView({
      model: group,
      collection: users,
    })

    // @ts-expect-error - Legacy Backbone typing
    const groupDetailView = new GroupDetailView({
      model: group,
      users,
    })

    // @ts-expect-error - Legacy Backbone typing
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

    // @ts-expect-error - Backbone View property
    view.render()
    // @ts-expect-error - Backbone View property
    view.$el.appendTo($(list))

    return view
  }

  beforeEach(() => {
    window.ENV = {
      // @ts-expect-error - Legacy Backbone typing
      permissions: {can_add_groups: true},
    }
    createView()
  })

  afterEach(() => {
    // @ts-expect-error - Legacy Backbone typing
    window.ENV = null
    // @ts-expect-error - Legacy Backbone typing
    if (container) {
      container.remove()
      container = null
    }
    // @ts-expect-error - Legacy Backbone typing
    view.remove()
    vi.restoreAllMocks()
  })

  // @ts-expect-error - Legacy Backbone typing
  const assertCollapsed = view => {
    expect(view.$el.hasClass('group-collapsed')).toBe(true)
    expect(view.$el.hasClass('group-expanded')).toBe(false)
  }

  // @ts-expect-error - Legacy Backbone typing
  const assertExpanded = view => {
    expect(view.$el.hasClass('group-collapsed')).toBe(false)
    expect(view.$el.hasClass('group-expanded')).toBe(true)
  }

  // Skipped: jQuery draggable not available in test environment - ARC-9215
  it('is accessible', async () => {
    // @ts-expect-error - Legacy Backbone typing
    const results = await axe.run(container, {
      rules: {
        'color-contrast': {enabled: false}, // Disable color contrast check since we're testing in a detached DOM
      },
      // @ts-expect-error - Legacy Backbone typing
      runOnly: ['wcag2a', 'wcag2aa'],
    })
    expect(results.violations).toHaveLength(0)
  })

  // Skipped: jQuery draggable not available in test environment - ARC-9215
  it('renders in collapsed state initially', () => {
    // @ts-expect-error - Legacy Backbone typing
    assertCollapsed(view)
  })

  // Skipped: jQuery draggable not available in test environment - ARC-9215
  it('expands and collapses when toggle button is clicked', () => {
    // @ts-expect-error - Legacy Backbone typing
    assertCollapsed(view)

    // @ts-expect-error - Legacy Backbone typing
    view.$('.toggle-group').eq(0).click()

    // @ts-expect-error - Legacy Backbone typing
    assertExpanded(view)

    // @ts-expect-error - Legacy Backbone typing
    view.$('.toggle-group').eq(0).click()

    // @ts-expect-error - Legacy Backbone typing
    assertCollapsed(view)
  })

  // Skipped: jQuery draggable not available in test environment - ARC-9215
  it('renders group users', () => {
    // @ts-expect-error - Legacy Backbone typing
    expect(view.$('.group-user')).toHaveLength(2)
  })

  // Skipped: jQuery draggable not available in test environment - ARC-9215
  it('removes the group after successful deletion', () => {
    vi.spyOn(window, 'confirm').mockImplementation(() => true)
    // @ts-expect-error - Legacy Backbone typing
    const removeSpy = vi.spyOn(view, 'remove')
    // @ts-expect-error - Legacy Backbone typing
    view.attach() // Ensure event listeners are attached

    // @ts-expect-error - Legacy Backbone typing
    view.model.trigger('destroy')

    expect(removeSpy).toHaveBeenCalled()
  })
})
