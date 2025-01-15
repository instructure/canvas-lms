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
import sinon from 'sinon'
import '@testing-library/jest-dom'

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

describe('RandomlyAssignMembersView', () => {
  let server
  let view
  let model
  let clock
  let originalEnv

  const queueResponse = (method, url, json) =>
    server.respondWith(method, url, [
      200,
      {
        'Content-Type': 'application/json',
      },
      JSON.stringify(json),
    ])

  beforeEach(() => {
    server = sinon.fakeServer.create()
    originalEnv = window.ENV
    window.ENV = {
      group_user_type: 'student',
      permissions: {can_manage_groups: true},
      IS_LARGE_ROSTER: false,
    }

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

    model = new GroupCategory({id: 20, name: 'Project Group'})
    view = new GroupCategoryView({model})

    queueResponse('GET', '/api/v1/group_categories/20/groups?per_page=50', groupsResponse)
    queueResponse(
      'GET',
      '/api/v1/group_categories/20/users?per_page=50&include[]=sections&exclude[]=pseudonym&unassigned=true&include[]=group_submissions',
      unassignedUsersResponse
    )

    view.render()
    view.$el.appendTo($('#fixtures'))

    server.respond()
    server.responses = []
  })

  afterEach(() => {
    server.restore()
    if (clock) {
      clock.restore()
    }
    window.ENV = originalEnv
    view.remove()
    document.body.innerHTML = ''
  })

  it('randomly assigns unassigned users', () => {
    // Initial state verification
    expect(document.querySelector('.progress-container')).toBeFalsy()
    expect(document.querySelector('[data-view=groups]')).toBeTruthy()
    expect(model.unassignedUsers().length).toBe(3)

    // Open options menu
    $('.icon-mini-arrow-down').simulate('click')

    // Click randomly assign option
    $('.randomly-assign-members').simulate('click')

    // Setup clock for progress polling
    clock = sinon.useFakeTimers()

    // Confirm random assignment
    $('.randomly-assign-members-confirm').simulate('click')

    // Handle POST request and initial progress check
    queueResponse(
      'POST',
      '/api/v1/group_categories/20/assign_unassigned_members',
      assignUnassignedMembersResponse
    )
    queueResponse('GET', /progress/, partialProgressResponse)
    server.respond()
    clock.tick(1)

    // Verify progress bar state
    expect(document.querySelector('.progress-container')).toBeTruthy()
    expect(document.querySelector('[data-view=groups]')).toBeFalsy()

    // Complete progress
    queueResponse('GET', /progress/, progressResponse)
    server.respond()
    clock.tick(1)

    // Handle model updates
    queueResponse(
      'GET',
      '/api/v1/group_categories/20?includes[]=unassigned_users_count&includes[]=groups_count',
      {
        ...groupCategoryResponse,
        groups_count: 1,
        unassigned_users_count: 0,
      }
    )
    server.respond()
    clock.tick(1)

    queueResponse('GET', '/api/v1/group_categories/20/groups?per_page=50', groupsResponse)
    server.respond()
    clock.tick(1)

    queueResponse(
      'GET',
      '/api/v1/group_categories/20/users?per_page=50&include[]=sections&exclude[]=pseudonym&unassigned=true&include[]=group_submissions',
      []
    )
    server.respond()
    clock.tick(1)

    // Final state verification
    expect(document.querySelector('.progress-container')).toBeFalsy()
    expect(document.querySelector('[data-view=groups]')).toBeTruthy()
    expect(model.unassignedUsers().length).toBe(0)
  })
})
