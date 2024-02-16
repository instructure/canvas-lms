/* eslint-disable qunit/resolve-async */
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
import GroupView from 'ui/features/manage_groups/backbone/views/GroupView'
import GroupUsersView from 'ui/features/manage_groups/backbone/views/GroupUsersView'
import GroupDetailView from 'ui/features/manage_groups/backbone/views/GroupDetailView'
import GroupUserCollection from '@canvas/groups/backbone/collections/GroupUserCollection'
import Group from '@canvas/groups/backbone/models/Group'
import fakeENV from 'helpers/fakeENV'
import assertions from 'helpers/assertions'

let view = null
let group = null
let users = null

QUnit.module('GroupView', {
  setup() {
    fakeENV.setup()
    ENV.permissions = {can_add_groups: true}
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
      {group}
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
    view.render()
    view.$el.appendTo($('#fixtures'))
  },
  teardown() {
    fakeENV.teardown()
    view.remove()
    document.getElementById('fixtures').innerHTML = ''
  },
})
test('it should be accessible', assert => {
  const done = assert.async()
  assertions.isAccessible(view, done, {a11yReport: true})
})
const assertCollapsed = function (view) {
  ok(view.$el.hasClass('group-collapsed'), 'expand visible')
  ok(!view.$el.hasClass('group-expanded'), 'collapse hidden')
}
const assertExpanded = function (view) {
  ok(!view.$el.hasClass('group-collapsed'), 'expand hidden')
  ok(view.$el.hasClass('group-expanded'), 'collapse visible')
}
test('initial state should be collapsed', () => assertCollapsed(view))

test('expand/collpase buttons', () => {
  view.$('.toggle-group').eq(0).click()
  assertExpanded(view)
  view.$('.toggle-group').eq(0).click()
  assertCollapsed(view)
})

test('renders groupUsers', () => {
  ok(view.$('.group-user').length)
})

test('removes the group after successful deletion', () => {
  const url = `/api/v1/groups/${view.model.get('id')}`
  const server = sinon.fakeServer.create()
  server.respondWith(url, [200, {'Content-Type': 'application/json'}, JSON.stringify({})])
  sandbox.stub(window, 'confirm').returns(true)
  view.$('.delete-group').click()
  server.respond()
  ok(!view.$el.hasClass('hidden'), 'group hidden')
  server.restore()
})
