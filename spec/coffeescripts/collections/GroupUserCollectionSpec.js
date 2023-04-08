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

import GroupUserCollection from '@canvas/groups/backbone/collections/GroupUserCollection'
import UnassignedGroupUserCollection from '@canvas/groups/backbone/collections/UnassignedGroupUserCollection'
import GroupCategory from '@canvas/groups/backbone/models/GroupCategory'
import GroupUser from '@canvas/groups/backbone/models/GroupUser'
import Group from '@canvas/groups/backbone/models/Group'
import Backbone from '@canvas/backbone'

let source = null
let target = null
let users = null
let group = null

QUnit.module('GroupUserCollection', {
  setup() {
    group = new Group({id: 1})
    const category = new GroupCategory()
    category._groups = new Backbone.Collection([group])
    users = [
      new GroupUser({
        id: 1,
        name: 'bob',
        sortable_name: 'bob',
        group: null,
      }),
      new GroupUser({
        id: 2,
        name: 'joe',
        sortable_name: 'joe',
        group: null,
      }),
    ]
    source = new UnassignedGroupUserCollection(users, {category})
    category._unassignedUsers = source
    target = new GroupUserCollection(null, {
      group,
      category,
    })
    target.loaded = true
    group._users = target
  },
})

test("moves user to target group's collection when group changes", () => {
  users[0].set('group', group)
  equal(source.length, 1)
  equal(target.length, 1)
})

test("removes user when target group's collection is not yet loaded", () => {
  users[0].set('group', new Group({id: 2})) // not the target
  equal(source.length, 1)
  equal(target.length, 0)
})
