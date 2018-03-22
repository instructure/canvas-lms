/*
 * Copyright (C) 2012 - present Instructure, Inc.
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
import Role from 'compiled/models/Role'
import RolesCollection from 'compiled/collections/RolesCollection'
import 'compiled/util/BaseRoleTypes'

QUnit.module('RolesCollection', {
  setup() {
    this.account_id = 2
  },
  teardown() {
    this.account_id = null
  }
})

test('generate the correct url for a collection of roles', 1, function() {
  const roles_collection = new RolesCollection(null, {
    contextAssetString: `account_${this.account_id}`
  })
  equal(roles_collection.url(), `/api/v1/accounts/${this.account_id}/roles`, 'roles collection url')
})

test('fetches a collection of roles', 1, function() {
  const server = sinon.fakeServer.create()
  const role1 = new Role()
  const role2 = new Role()
  const roles_collection = new RolesCollection(null, {
    contextAssetString: `account_${this.account_id}`
  })
  roles_collection.fetch({
    success: () => equal(roles_collection.size(), 2, 'Adds all of the roles to the collection')
  })
  server.respond('GET', roles_collection.url(), [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify([role1, role2])
  ])
  server.restore()
})

test('keeps roles in order based on sort order then alphabetically', () => {
  RolesCollection.sortOrder = ['AccountMembership', 'StudentEnrollment', 'TaEnrollment']
  const roleFirst = new Role({
    base_role_type: 'AccountMembership',
    role: 'AccountAdmin'
  })
  const roleSecond = new Role({
    base_role_type: 'AccountMembership',
    role: 'Another account membership'
  })
  const roleThird = new Role({
    base_role_type: 'StudentEnrollment',
    role: 'A student Role'
  })
  const roleFourth = new Role({
    base_role_type: 'StudentEnrollment',
    role: 'B student Role'
  })
  const roleFith = new Role({
    base_role_type: 'TaEnrollment',
    role: 'A TA role'
  })
  const roleCollection = new RolesCollection([
    roleThird,
    roleSecond,
    roleFirst,
    roleFourth,
    roleFith
  ])
  equal(roleCollection.models[0], roleFirst, 'First role is in order')
  equal(roleCollection.models[1], roleSecond, 'Second role is in order')
  equal(roleCollection.models[2], roleThird, 'Third role is in order')
  equal(roleCollection.models[3], roleFourth, 'Forth role is in order')
  equal(roleCollection.models[4], roleFith, 'Fith role is in order')
})
