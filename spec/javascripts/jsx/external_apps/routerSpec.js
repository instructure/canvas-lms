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

import regularizePathname from 'jsx/external_apps/lib/regularizePathname'

QUnit.module('External Apps Client-side Router', {
  before() {
    window.ENV = window.ENV || {}
    window.ENV.TESTING_PATH = '/settings/something'
  }
})

test('regularizePathname removes trailing slash', () => {
  const fakeCtx = {
    pathname: '/app/something/else/'
  }

  // No op for next().
  const fakeNext = () => {}

  regularizePathname(fakeCtx, fakeNext)

  equal(fakeCtx.pathname, '/app/something/else', 'trailing slash is gone')
})

test('regularizePathname removes url hash fragment', () => {
  const fakeCtx = {
    hash: 'blah-ha-ba',
    pathname: '/app/something/else/#blah-ha-ba'
  }

  // No op for next().
  const fakeNext = () => {}

  regularizePathname(fakeCtx, fakeNext)

  equal(fakeCtx.pathname, '/app/something/else', 'url hash fragment is gone')
})
