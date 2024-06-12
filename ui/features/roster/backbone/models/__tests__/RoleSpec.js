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
import fakeENV from '@canvas/common/fakeENV'
import {clone, omit} from 'lodash'
import Backbone from '@canvas/backbone'

class Account extends Backbone.Model {
  present = () => clone(this.attributes)

  toJSON = () => ({
    id: this.get('id'),
    account: omit(this.attributes, ['id']),
  })
}

Account.prototype.urlRoot = '/api/v1/accounts'

QUnit.module('RoleModel', {
  setup() {
    this.account = new Account({id: 4})
    this.role = new Role({account: this.account})
    this.server = sinon.fakeServer.create()
    fakeENV.setup({ACCOUNT_ID: 3})
  },
  teardown() {
    this.server.restore()
    this.role = null
    this.account_id = null
    fakeENV.teardown()
  },
})

// eslint-disable-next-line qunit/no-test-expect-argument
test('generates the correct url for existing and non-existing roles', 2, function () {
  equal(this.role.url(), '/api/v1/accounts/3/roles', 'non-existing role url')
  this.role.fetch({
    success: () => equal(this.role.url(), '/api/v1/accounts/3/roles/1', 'existing role url'),
  })
  return this.server.respond('GET', this.role.url(), [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify({
      role: 'existingRole',
      id: '1',
      account: this.account,
    }),
  ])
})
