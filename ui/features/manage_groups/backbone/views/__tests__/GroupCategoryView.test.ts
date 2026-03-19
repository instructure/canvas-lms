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
import {useScope as createI18nScope} from '@canvas/i18n'
import GroupCategoryView from '../GroupCategoryView'
import {Model, Collection} from '@canvas/backbone'
import fakeENV from '@canvas/test-utils/fakeENV'

const I18n = createI18nScope('groups')

describe('GroupCategoryView', () => {
  // @ts-expect-error - Legacy Backbone typing
  let model, groups, unassignedUsers

  beforeEach(() => {
    fakeENV.setup({
      group_user_type: 'student',
      permissions: {
        can_manage_groups: true,
      },
    })

    $.flashError = vi.fn()
    $.flashMessage = vi.fn()

    // Mock jQuery UI droppable and related methods
    $.fn.droppable = vi.fn(function () {
      // @ts-expect-error - Legacy Backbone typing
      return this
    })
    $.fn.unbind = vi.fn(function () {
      // @ts-expect-error - Legacy Backbone typing
      return this
    })
    $.fn.on = vi.fn(function () {
      // @ts-expect-error - Legacy Backbone typing
      return this
    })
    $.fn.parent = vi.fn(function () {
      // @ts-expect-error - Legacy Backbone typing
      return $(this)
    })

    groups = new Collection()
    groups.resourceName = 'groups'
    groups.load = vi.fn(() => Promise.resolve())
    groups.constructor.prototype.resourceName = 'groups'
    unassignedUsers = new Collection()
    unassignedUsers.resourceName = 'users'
    unassignedUsers.load = vi.fn(() => Promise.resolve())
    unassignedUsers.constructor.prototype.resourceName = 'users'

    model = new Model({
      name: 'Test Group Category',
      role: 'student',
      allows_multiple_memberships: false,
    })
    model.resourceName = 'group_categories'
    model.constructor.prototype.resourceName = 'group_categories'
    // @ts-expect-error - Legacy Backbone typing
    model.groups = () => groups
    // @ts-expect-error - Legacy Backbone typing
    model.unassignedUsers = () => unassignedUsers
    model.progressModel = new Model()
    model.fetch = vi.fn(options => options.success?.())
    model.present = () => ({
      // @ts-expect-error - Legacy Backbone typing
      ...model.attributes,
      randomlyAssignStudentsInProgress: false,
    })
    model.groupsCount = () => groups.length
    model.unassignedUsersCount = () => unassignedUsers.length
    model.canMessageUnassignedMembers = () => true
    model.canAssignUnassignedMembers = () => true
    model.isLocked = () => false
    model.downloadGroupCategoryRosterCSVPath = () => '/api/v1/group_categories/123/export'

    // @ts-expect-error - Legacy Backbone typing
    new GroupCategoryView({model})
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  const progressMessage = (groups = 0, users = 0) => {
    const message = {
      type: 'import_groups',
      groups,
      users,
    }
    return JSON.stringify(message)
  }

  describe('flash messages based on importStatus', () => {
    it('displays an error message when importStatus is failed', () => {
      // @ts-expect-error - Legacy Backbone typing
      model.progressModel.set({
        workflow_state: 'failed',
        message: progressMessage(),
      })
      // @ts-expect-error - Legacy Backbone typing
      model.trigger('progressResolved')
      expect($.flashError).toHaveBeenCalledWith(
        'Your groups could not be uploaded. Check formatting and try again.',
      )
      expect($.flashMessage).not.toHaveBeenCalled()
      // @ts-expect-error - Legacy Backbone typing
      expect(model.fetch).toHaveBeenCalled()
    })

    it('displays a success message when importStatus is completed', () => {
      const successMessage = I18n.t(
        'Your %{groups} groups and %{users} students were successfully uploaded',
        {
          groups: 2,
          users: 3,
        },
      )
      // @ts-expect-error - Legacy Backbone typing
      model.progressModel.set({
        workflow_state: 'completed',
        message: progressMessage(2, 3),
      })
      // @ts-expect-error - Legacy Backbone typing
      model.trigger('progressResolved')
      expect($.flashMessage).toHaveBeenCalledWith(successMessage)
      expect($.flashError).not.toHaveBeenCalled()
      // @ts-expect-error - Legacy Backbone typing
      expect(model.fetch).toHaveBeenCalled()
    })

    it('does not display any flash message for other import statuses', () => {
      // @ts-expect-error - Legacy Backbone typing
      model.progressModel.set({
        workflow_state: 'running',
      })
      // @ts-expect-error - Legacy Backbone typing
      model.trigger('progressResolved')
      expect($.flashMessage).not.toHaveBeenCalled()
      expect($.flashError).not.toHaveBeenCalled()
      // @ts-expect-error - Legacy Backbone typing
      expect(model.fetch).toHaveBeenCalled()
    })
  })
})
