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

import Role from '../Role'
import fakeENV from '@canvas/test-utils/fakeENV'
import {clone, omit} from 'lodash'
import Backbone from '@canvas/backbone'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

class Account extends Backbone.Model {
  present = () => clone(this.attributes)

  toJSON = () => ({
    id: this.get('id'),
    account: omit(this.attributes, ['id']),
  })
}

Account.prototype.urlRoot = '/api/v1/accounts'

const server = setupServer()

describe('RoleModel', () => {
  let account
  let role

  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  beforeEach(() => {
    account = new Account({id: 4})
    role = new Role({account})
    fakeENV.setup({ACCOUNT_ID: 3})
  })

  afterEach(() => {
    role = null
    fakeENV.teardown()
  })

  test('generates the correct url for existing and non-existing roles', async () => {
    expect(role.url()).toBe('/api/v1/accounts/3/roles')

    server.use(
      http.get('/api/v1/accounts/3/roles', () => {
        return HttpResponse.json({
          role: 'existingRole',
          id: '1',
          account,
        })
      }),
    )

    await new Promise(resolve => {
      role.fetch({
        success: () => {
          expect(role.url()).toBe('/api/v1/accounts/3/roles/1')
          resolve()
        },
      })
    })
  })
})
