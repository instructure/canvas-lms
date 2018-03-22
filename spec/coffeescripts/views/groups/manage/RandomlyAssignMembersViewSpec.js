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
import _ from 'underscore'
import GroupCategoryView from 'compiled/views/groups/manage/GroupCategoryView'
import RandomlyAssignMembersView from 'compiled/views/groups/manage/RandomlyAssignMembersView'
import GroupCategory from 'compiled/models/GroupCategory'
import 'helpers/fakeENV'

let server = null
let view = null
let model = null
const globalObj = this
let clock = null

const queueResponse = (method, url, json) =>
  server.respondWith(method, url, [
    200,
    {
      'Content-Type': 'application/json'
    },
    JSON.stringify(json)
  ])

const groupsResponse =
  // GET "/api/v1/group_categories/20/groups?per_page=50&include[]=sections"
  [
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
      role: null
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
      role: null
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
      role: null
    }
  ]

const unassignedUsersResponse =
  // GET "/api/v1/group_categories/20/users?unassigned=true&per_page=50"
  [
    {
      id: 41,
      name: 'Panda Farmer',
      sortable_name: 'Farmer, Panda',
      short_name: 'Panda Farmer',
      sis_user_id: '337733',
      sis_login_id: 'pandafarmer134123@gmail.com',
      login_id: 'pandafarmer134123@gmail.com'
    },
    {
      id: 45,
      name: 'Elmer Fudd',
      sortable_name: 'Fudd, Elmer',
      short_name: 'Elmer Fudd',
      login_id: 'elmerfudd'
    },
    {
      id: 2,
      name: 'Leeroy Jenkins',
      sortable_name: 'Jenkins, Leeroy',
      short_name: 'Leeroy Jenkins'
    }
  ]

const assignUnassignedMembersResponse =
  //  POST /api/v1/group_categories/20/assign_unassigned_members
  {
    completion: 0,
    context_id: 20,
    context_type: 'GroupCategory',
    created_at: '2013-07-17T11:05:38-06:00',
    id: 105,
    message: null,
    tag: 'assign_unassigned_members',
    updated_at: '2013-07-17T11:05:38-06:00',
    user_id: null,
    workflow_state: 'running',
    url: 'http://localhost:3000/api/v1/progress/105'
  }
const partialProgressResponse =
  // GET  /api/v1/progress/105
  {
    completion: 50,
    context_id: 20,
    context_type: 'GroupCategory',
    created_at: '2013-07-17T11:05:38-06:00',
    id: 105,
    message: null,
    tag: 'assign_unassigned_members',
    updated_at: '2013-07-17T11:05:44-06:00',
    user_id: null,
    workflow_state: 'running',
    url: 'http://localhost:3000/api/v1/progress/105'
  }
const progressResponse =
  // GET  /api/v1/progress/105
  {
    completion: 100,
    context_id: 20,
    context_type: 'GroupCategory',
    created_at: '2013-07-17T11:05:38-06:00',
    id: 105,
    message: null,
    tag: 'assign_unassigned_members',
    updated_at: '2013-07-17T11:05:44-06:00',
    user_id: null,
    workflow_state: 'completed',
    url: 'http://localhost:3000/api/v1/progress/105'
  }

const groupCategoryResponse =
  // GET /api/v1/group_categories/20
  {
    id: 20,
    name: 'Gladiators',
    role: null,
    self_signup: 'enabled',
    context_type: 'Course',
    course_id: 1
  }

QUnit.module('RandomlyAssignMembersView', {
  setup() {
    server = sinon.fakeServer.create()
    this._ENV = window.ENV
    window.ENV = {
      group_user_type: 'student',
      IS_LARGE_ROSTER: false
    }

    model = new GroupCategory({id: 20, name: 'Project Group'})
    view = new GroupCategoryView({model})

    // #
    // instantiating GroupCategoryView will run GroupCategory.groups()
    //   therefore, server will now have one GET request for "/api/v1/group_categories/20/groups?per_page=50"
    //   and one GET request for "/api/v1/group_categories/20/users?unassigned=true&per_page=50"
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
  },

  teardown() {
    server.restore()
    clock.restore()
    window.ENV = this._ENV
    view.remove()
    document.getElementById('fixtures').innerHTML = ''
  }
})

test('randomly assigns unassigned users', () => {
  let $progressContainer = $('.progress-container')
  let $groups = $('[data-view=groups]')
  equal($progressContainer.length, 0, 'Progress bar hidden by default')
  equal($groups.length, 1, 'Groups shown by default')
  equal(model.unassignedUsers().length, 3, 'There are unassigned users to begin with')

  // #
  // click the options cog to reveal the options menu
  const $cog = $('.icon-mini-arrow-down')
  $cog.click()

  // #
  // click the randomly assign students option to open up the confirmation dialog view
  const $assignOptionLink = $('.randomly-assign-members')
  $assignOptionLink.click()

  // #
  // so that we can fully manage the progress polling, fake the clock
  clock = sinon.useFakeTimers()

  // #
  // click the confirm button to run the assignment process
  const $confirmAssignButton = $('.randomly-assign-members-confirm')
  $confirmAssignButton.click()

  // #
  // the click will fire a POST request to
  // "/api/v1/group_categories/20/assign_unassigned_members" and kick off
  // polling for progress
  queueResponse(
    'POST',
    '/api/v1/group_categories/20/assign_unassigned_members',
    assignUnassignedMembersResponse
  )
  queueResponse('GET', /progress/, partialProgressResponse)
  server.respond()

  // #
  // verify that there is progress bar
  $progressContainer = $('.progress-container')
  $groups = $('[data-view=groups]')
  equal($progressContainer.length, 1, 'Shows progress bar during assigning process')
  equal($groups.length, 0, 'Hides groups during assigning process')

  // #
  // forward the clock so that we get another request for progress, and reset
  // the stored responses so that we can respond with complete progress (from
  // the same url)
  clock.tick(1001)

  // #
  // progressable mixin ensures that the progress model is now polling, respond to it with a 100% completion
  queueResponse('GET', /progress/, progressResponse)
  server.respond()

  // #
  // the 100% completion response will cascade a model.fetch request
  // + model.groups().fetch + model.unassignedUsers().fetch calls
  queueResponse(
    'GET',
    '/api/v1/group_categories/20?includes[]=unassigned_users_count&includes[]=groups_count',
    {
      ...groupCategoryResponse,
      groups_count: 1,
      unassigned_users_count: 0
    }
  )
  server.respond()

  queueResponse('GET', '/api/v1/group_categories/20/groups?per_page=50', groupsResponse)
  server.respond()

  queueResponse(
    'GET',
    '/api/v1/group_categories/20/users?per_page=50&include[]=sections&exclude[]=pseudonym&unassigned=true&include[]=group_submissions',
    []
  )
  server.respond()

  // #
  // verify that the groups are shown again and the progress bar is hidden
  $progressContainer = $('.progress-container')
  $groups = $('[data-view=groups]')
  equal($progressContainer.length, 0, 'Hides progress bar after assigning process')
  equal($groups.length, 1, 'Reveals groups after assigning process')
  equal(model.unassignedUsers().length, 0, 'There are no longer unassigned users')
})
