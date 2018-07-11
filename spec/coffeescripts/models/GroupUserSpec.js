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

import Backbone from 'Backbone'
import Group from 'compiled/models/Group'
import GroupUser from 'compiled/models/GroupUser'
import GroupCategory from 'compiled/models/GroupCategory'
import $ from 'jquery'

QUnit.module('GroupUser', {
  setup() {
    this.groupUser = new GroupUser({category: new GroupCategory()})
    this.leaveGroupStub = sandbox.stub(this.groupUser, 'leaveGroup')
    this.joinGroupStub = sandbox.stub(this.groupUser, 'joinGroup')
  }
})

test('updates group correctly upon save and fires joinGroup and leaveGroup appropriately', function() {
  const group1 = new Group({id: 777})
  this.groupUser.save({group: group1})
  equal(this.groupUser.get('group'), group1)
  equal(this.joinGroupStub.callCount, 1)
  ok(this.joinGroupStub.calledWith(group1))
  equal(this.leaveGroupStub.callCount, 0)
  const group2 = new Group({id: 123})
  this.groupUser.save({group: group2})
  equal(this.groupUser.get('group'), group2)
  equal(this.joinGroupStub.callCount, 2)
  ok(this.joinGroupStub.calledWith(group2))
  this.groupUser.save({group: null})
  equal(this.groupUser.get('group'), null)
  equal(this.joinGroupStub.callCount, 2)
  equal(this.leaveGroupStub.callCount, 1)
})
