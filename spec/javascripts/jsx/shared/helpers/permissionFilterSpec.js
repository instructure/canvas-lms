/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import applyPermissions from 'jsx/shared/helpers/permissionFilter'

QUnit.module('Permissions Filter Helper Function')

test('Item requires no permissions', () => {
  const items = [
    {
      permissions: []
    }
  ]

  const permissions = {}
  const results = applyPermissions(items, permissions)

  equal(results.length, 1, 'item is not filtered')
})

test('User permissions fully match item permissions', () => {
  const items = [
    {
      permissions: ['perm1', 'perm2']
    }
  ]

  const permissions = {
    perm2: true,
    perm1: true
  }

  const results = applyPermissions(items, permissions)

  equal(results.length, 1, 'item is not filetered')
})

test('User permissions partially match item permissions', () => {
  const items = [
    {
      permissions: ['perm1', 'perm2']
    }
  ]

  const permissions = {
    perm1: true
  }

  const results = applyPermissions(items, permissions)

  equal(results.length, 0, 'item is filtered')
})

test('User permissions fully mismatch required permissions', () => {
  const items = [
    {
      permissions: ['perm1', 'perm2']
    }
  ]

  const permissions = {}
  const results = applyPermissions(items, permissions)

  equal(results.length, 0, 'item is filtered')
})
