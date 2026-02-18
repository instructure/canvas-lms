/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import GroupCategoryDetailView from '../GroupCategoryDetailView'
import {Model, Collection} from '@canvas/backbone'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('GroupCategoryDetailView', () => {
  // @ts-expect-error - Legacy Backbone typing
  let model, groups, unassignedUsers, view

  beforeEach(() => {
    groups = new Collection()
    groups.resourceName = 'groups'
    groups.constructor.prototype.resourceName = 'groups'

    unassignedUsers = new Collection()
    unassignedUsers.resourceName = 'users'
    unassignedUsers.constructor.prototype.resourceName = 'users'
    unassignedUsers.urls = {}

    model = new Model({
      id: '123',
      name: 'Test Group Category',
      role: 'student',
    })
    model.resourceName = 'group_categories'
    model.constructor.prototype.resourceName = 'group_categories'
    // @ts-expect-error - Legacy Backbone typing
    model.groups = () => groups
    // @ts-expect-error - Legacy Backbone typing
    model.unassignedUsers = () => unassignedUsers
    model.progressModel = new Model()
    model.canMessageUnassignedMembers = vi.fn(() => false)
    model.canAssignUnassignedMembers = vi.fn(() => false)
    model.isLocked = vi.fn(() => false)
    model.downloadGroupCategoryRosterCSVPath = vi.fn(() => '/api/v1/group_categories/123/export')
  })

  afterEach(() => {
    // @ts-expect-error - Legacy Backbone typing
    if (view) {
      view.remove()
    }
    fakeENV.teardown()
  })

  describe('download course roster CSV link', () => {
    it('renders download CSV link when canManage is true', () => {
      fakeENV.setup({
        group_user_type: 'student',
        permissions: {
          can_manage_groups: true,
        },
      })

      // @ts-expect-error - Legacy Backbone typing
      view = new GroupCategoryDetailView({
        // @ts-expect-error - Legacy Backbone typing
        model,
        // @ts-expect-error - Legacy Backbone typing
        collection: groups,
      })

      // @ts-expect-error - Backbone View property
      const $el = view.render().$el
      document.body.appendChild($el[0])

      const downloadLink = $el.find('.download-group-category-roster-csv')
      expect(downloadLink).toHaveLength(1)
      expect(downloadLink.attr('href')).toBe('/api/v1/group_categories/123/export')
    })

    it('does not render download CSV link when canManage is false due to lack of permissions', () => {
      fakeENV.setup({
        group_user_type: 'student',
        permissions: {
          can_manage_groups: false,
        },
      })

      // @ts-expect-error - Legacy Backbone typing
      view = new GroupCategoryDetailView({
        // @ts-expect-error - Legacy Backbone typing
        model,
        // @ts-expect-error - Legacy Backbone typing
        collection: groups,
      })

      // @ts-expect-error - Backbone View property
      const $el = view.render().$el
      document.body.appendChild($el[0])

      const downloadLink = $el.find('.download-group-category-roster-csv')
      expect(downloadLink).toHaveLength(0)
    })

    it('does not render download CSV link when canManage is false due to locked model', () => {
      fakeENV.setup({
        group_user_type: 'student',
        permissions: {
          can_manage_groups: true,
        },
      })

      // @ts-expect-error - Legacy Backbone typing
      model.isLocked = vi.fn(() => true)

      // @ts-expect-error - Legacy Backbone typing
      view = new GroupCategoryDetailView({
        // @ts-expect-error - Legacy Backbone typing
        model,
        // @ts-expect-error - Legacy Backbone typing
        collection: groups,
      })

      // @ts-expect-error - Backbone View property
      const $el = view.render().$el
      document.body.appendChild($el[0])

      const downloadLink = $el.find('.download-group-category-roster-csv')
      expect(downloadLink).toHaveLength(0)
    })
  })
})
