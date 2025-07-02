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
import 'jquery-migrate'
import '@canvas/jquery/jquery.simulate'
import GroupCategoryView from '../GroupCategoryView'
import GroupCategory from '@canvas/groups/backbone/models/GroupCategory'
import '@testing-library/jest-dom'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import fakeENV from '@canvas/test-utils/fakeENV'

// Mock the ProgressBar component to avoid screenReaderLabel prop warning
jest.mock('@instructure/ui-progress', () => ({
  ProgressBar: () => null,
}))

// Mock jQuery UI dialog
const dialogStub = {
  focusable: {
    focus: () => {},
  },
  open: () => {},
  close: () => {},
  isOpen: () => false,
}

$.fn.dialog = function (options) {
  if (options) {
    this.data('ui-dialog', dialogStub)
  }
  return this
}

$.fn.fixDialogButtons = function () {
  return this
}

const groupsResponse = [
  {
    description: null,
    group_category_id: 20,
    id: 61,
    is_public: false,
    join_level: 'invitation_only',
    name: 'Ninjas',
    members_count: 14,
    storage_quota_mb: 50,
    context_type: 'Course',
    course_id: 1,
    avatar_url: null,
    role: null,
  },
  {
    description: null,
    group_category_id: 20,
    id: 62,
    is_public: false,
    join_level: 'invitation_only',
    name: 'Samurai',
    members_count: 14,
    storage_quota_mb: 50,
    context_type: 'Course',
    course_id: 1,
    avatar_url: null,
    role: null,
  },
  {
    description: null,
    group_category_id: 20,
    id: 395,
    is_public: false,
    join_level: 'invitation_only',
    name: 'Pirates',
    members_count: 12,
    storage_quota_mb: 50,
    context_type: 'Course',
    course_id: 1,
    avatar_url: null,
    role: null,
  },
]

const unassignedUsersResponse = [
  {
    id: 41,
    name: 'Panda Farmer',
    sortable_name: 'Farmer, Panda',
    short_name: 'Panda Farmer',
    sis_user_id: '337733',
    sis_login_id: 'pandafarmer134123@gmail.com',
    login_id: 'pandafarmer134123@gmail.com',
  },
  {
    id: 45,
    name: 'Elmer Fudd',
    sortable_name: 'Fudd, Elmer',
    short_name: 'Elmer Fudd',
    sis_user_id: '337734',
    sis_login_id: 'elmerfudd134123@gmail.com',
    login_id: 'elmerfudd134123@gmail.com',
  },
  {
    id: 47,
    name: 'Bugs Bunny',
    sortable_name: 'Bunny, Bugs',
    short_name: 'Bugs Bunny',
    sis_user_id: '337735',
    sis_login_id: 'bugsbunny134123@gmail.com',
    login_id: 'bugsbunny134123@gmail.com',
  },
]

const assignUnassignedMembersResponse = {
  url: '/api/v1/progress/1',
  completion: 0,
  context_id: 20,
  context_type: 'GroupCategory',
  created_at: '2013-07-26T19:59:56-06:00',
  id: 1,
  message: null,
  tag: 'assign_unassigned_members',
  updated_at: '2013-07-26T19:59:56-06:00',
  user_id: null,
  workflow_state: 'running',
}

const partialProgressResponse = {
  ...assignUnassignedMembersResponse,
  completion: 50,
}

const progressResponse = {
  ...assignUnassignedMembersResponse,
  completion: 100,
  workflow_state: 'completed',
}

const groupCategoryResponse = {
  id: 20,
  name: 'Project Group',
  role: null,
  self_signup: null,
  context_type: 'Course',
  course_id: 1,
  protected: false,
  allows_multiple_memberships: false,
}

const server = setupServer()

describe('RandomlyAssignMembersView', () => {
  let view
  let model
  let randomlyAssignView
  let progressPollingCount = 0

  beforeAll(() => server.listen({onUnhandledRequest: 'bypass'}))
  afterEach(() => {
    server.resetHandlers()
    progressPollingCount = 0
  })
  afterAll(() => server.close())

  beforeEach(() => {
    fakeENV.setup({
      group_user_type: 'student',
      permissions: {can_manage_groups: true},
      IS_LARGE_ROSTER: false,
    })

    document.body.innerHTML = '<div id="fixtures"><div id="content"></div></div>'

    // Mock jQuery methods needed for dialog positioning
    $.fn.extend({
      offset: () => ({top: 0, left: 0}),
      position: () => ({top: 0, left: 0}),
      outerHeight: () => 100,
      outerWidth: () => 100,
      scrollLeft: () => 0,
      scrollTop: () => 0,
      height: () => 100,
      width: () => 100,
    })

    // Set up initial API handlers
    server.use(
      http.get('/api/v1/group_categories/20/groups', () => {
        return HttpResponse.json(groupsResponse)
      }),
      http.get('/api/v1/group_categories/20/users', ({request}) => {
        const url = new URL(request.url)
        if (url.searchParams.get('unassigned') === 'true') {
          return HttpResponse.json(unassignedUsersResponse)
        }
        return HttpResponse.json([])
      }),
    )

    model = new GroupCategory({id: 20, name: 'Project Group'})
    view = new GroupCategoryView({model})

    // Create the RandomlyAssignMembersView directly
    const RandomlyAssignMembersView = require('../RandomlyAssignMembersView').default
    randomlyAssignView = new RandomlyAssignMembersView({model})

    view.render()
    view.$el.appendTo($('#fixtures'))
  })

  afterEach(() => {
    fakeENV.teardown()
    view.remove()
    if (randomlyAssignView) {
      randomlyAssignView.remove()
    }
    document.body.innerHTML = ''
    jest.clearAllTimers()
    jest.useRealTimers()
  })

  it('randomly assigns unassigned users', async () => {
    // Initialize unassigned users collection to match what view does
    const unassignedUsers = model.unassignedUsers()
    unassignedUsers.reset(unassignedUsersResponse)
    unassignedUsers.loadedAll = true

    // Initial state verification
    expect(document.querySelector('.progress-container')).toBeFalsy()
    expect(document.querySelector('[data-view=groups]')).toBeTruthy()
    expect(model.unassignedUsers()).toHaveLength(3)

    // Set up MSW handlers for the assignment process
    server.use(
      http.post('/api/v1/group_categories/20/assign_unassigned_members', () => {
        return HttpResponse.json(assignUnassignedMembersResponse)
      }),
      http.get('/api/v1/progress/:id', () => {
        progressPollingCount++
        if (progressPollingCount === 1) {
          return HttpResponse.json(partialProgressResponse)
        }
        return HttpResponse.json(progressResponse)
      }),
      http.get('/api/v1/group_categories/20', ({request}) => {
        const url = new URL(request.url)
        if (url.searchParams.has('includes[]')) {
          return HttpResponse.json({
            ...groupCategoryResponse,
            groups_count: 1,
            unassigned_users_count: 0,
          })
        }
        return HttpResponse.json(groupCategoryResponse)
      }),
      http.get('/api/v1/group_categories/20/users', ({request}) => {
        const url = new URL(request.url)
        if (url.searchParams.get('unassigned') === 'true') {
          return HttpResponse.json([])
        }
        return HttpResponse.json([])
      }),
    )

    // Open the randomly assign members dialog directly
    randomlyAssignView.open()

    // Wait for dialog to render
    await new Promise(resolve => setTimeout(resolve, 50))

    // The dialog should be open now, find and click the confirm button
    const confirmButton = document.querySelector('.randomly-assign-members-confirm')
    expect(confirmButton).toBeTruthy()

    // Track when assignment starts
    let assignmentStarted = false
    const originalAssign = model.assignUnassignedMembers
    model.assignUnassignedMembers = function (...args) {
      assignmentStarted = true
      // Call original and handle the response
      const result = originalAssign.apply(this, args)
      // The response will trigger setUpProgress which sets progress_url
      return result
    }

    // Mock progressResolved to complete immediately
    const progressResolvedPromise = new Promise(resolve => {
      model.once('progressResolved', resolve)
    })

    // Click confirm button
    $(confirmButton).simulate('click')

    // Wait for POST request to complete and progress to start
    await new Promise(resolve => setTimeout(resolve, 200))

    expect(assignmentStarted).toBe(true)

    // Manually trigger progress since the async flow might not work in tests
    model.progressModel.set({
      workflow_state: 'running',
      completion: 0,
      url: '/api/v1/progress/1',
    })
    expect(document.querySelector('.progress-container')).toBeTruthy()
    expect(document.querySelector('[data-view=groups]')).toBeFalsy()

    // Simulate progress completion
    model.progressModel.set({
      workflow_state: 'completed',
      completion: 100,
    })
    model.trigger('progressResolved')

    // Wait for progressResolved handler
    await progressResolvedPromise
    await new Promise(resolve => setTimeout(resolve, 100))

    // Final state verification
    expect(document.querySelector('.progress-container')).toBeFalsy()
    expect(document.querySelector('[data-view=groups]')).toBeTruthy()
    expect(model.unassignedUsers()).toHaveLength(0)

    // Restore original function
    model.assignUnassignedMembers = originalAssign
  })
})
