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

import Role from '../../models/Role'
import RolesCollection from '../RolesCollection'
import sinon from 'sinon'

describe('RolesCollection', () => {
  let account_id

  beforeEach(() => {
    account_id = 2
  })

  afterEach(() => {
    account_id = null
  })

  test('generate the correct url for a collection of roles', () => {
    const roles_collection = new RolesCollection(null, {
      contextAssetString: `account_${account_id}`,
    })
    expect(roles_collection.url()).toBe(`/api/v1/accounts/${account_id}/roles`)
  })

  test('fetches a collection of roles', () => {
    const server = sinon.fakeServer.create()
    const role1 = new Role()
    const role2 = new Role()
    const roles_collection = new RolesCollection(null, {
      contextAssetString: `account_${account_id}`,
    })

    roles_collection.fetch({
      success: () => {
        expect(roles_collection.size()).toBe(2)
      },
    })

    server.respond('GET', roles_collection.url(), [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify([role1, role2]),
    ])

    server.restore()
  })

  test('keeps roles in order based on sort order then alphabetically', () => {
    RolesCollection.sortOrder = ['AccountMembership', 'StudentEnrollment', 'TaEnrollment']

    const roleFirst = new Role({
      base_role_type: 'AccountMembership',
      role: 'AccountAdmin',
    })
    const roleSecond = new Role({
      base_role_type: 'AccountMembership',
      role: 'Another account membership',
    })
    const roleThird = new Role({
      base_role_type: 'StudentEnrollment',
      role: 'A student Role',
    })
    const roleFourth = new Role({
      base_role_type: 'StudentEnrollment',
      role: 'B student Role',
    })
    const roleFith = new Role({
      base_role_type: 'TaEnrollment',
      role: 'A TA role',
    })

    const roleCollection = new RolesCollection([
      roleThird,
      roleSecond,
      roleFirst,
      roleFourth,
      roleFith,
    ])

    expect(roleCollection.models[0]).toBe(roleFirst)
    expect(roleCollection.models[1]).toBe(roleSecond)
    expect(roleCollection.models[2]).toBe(roleThird)
    expect(roleCollection.models[3]).toBe(roleFourth)
    expect(roleCollection.models[4]).toBe(roleFith)
  })
})
